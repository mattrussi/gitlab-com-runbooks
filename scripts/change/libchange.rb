require 'gitlab'
require 'io/console'

class Change
  attr_accessor :id
  attr_accessor :meta
  attr_accessor :prev

  def initialize(id)
    @id = id
    @meta = {}
    @prev = {}
  end

  def run_action(action)
    puts action.describe(self)

    if action.skip_if(self)
      puts "Skipping."
      return
    end

    return if ENV["CHANGE_DRY_RUN"] == 'true'

    action.apply(self)

    # we allow nil in case actions want to raise on their own
    raise "verify of action failed: #{action}" if action.verify(self) == false

    @prev = action
  end

  def in_progress(*args)
    run_action InProgress.new(*args)
  end

  def merge_mr(*args)
    run_action MergeMR.new(*args)
  end

  def cmd(*args)
    run_action Cmd.new(*args)
  end

  def confirm_prompt(*args)
    run_action ConfirmPrompt.new(*args)
  end

  def expect(*args, &block)
    run_action Expect.new(*args, &block)
  end

  class InProgress
    def describe(c)
      "Setting change::in-progress label"
    end

    def skip_if(c)
      Gitlab.issue('gitlab-com/gl-infra/production', c.id).labels.include?('change::in-progress')
    end

    def apply(c)
      Gitlab.edit_issue('gitlab-com/gl-infra/production', c.id, { add_labels: 'change::in-progress' })
    end

    def verify(c)
      Gitlab.issue('gitlab-com/gl-infra/production', c.id).labels.include?('change::in-progress')
    end
  end

  class MergeMR
    def initialize(project, mr_id)
      @project = project
      @mr_id = mr_id
    end

    def describe(c)
      "Merging MR #{@project} #{@mr_id}"
    end

    def skip_if(c)
      Gitlab.merge_request(@project, @mr_id).state == 'merged'
    end

    def apply(c)
      Gitlab.accept_merge_request(@project, @mr_id)
    end

    def verify(c)
      Gitlab.merge_request(@project, @mr_id).state == 'merged'
    end
  end

  class Cmd
    attr_accessor :output

    def initialize(*cmd)
      @cmd = cmd
    end

    def describe(c)
      "Running shell command: #{@cmd}"
    end

    def skip_if(c)
    end

    def apply(c)
      f = IO.popen(@cmd)
      @output = f.readlines.join.gsub("\r", '')
      f.close

      @exit_code = $?

      c.meta["cmd_output"] = @output
      puts @output
    end

    def verify(c)
      @exit_code == 0
    end
  end

  class ConfirmPrompt
    def describe(c)
      "Continue? (y/n)"
    end

    def skip_if(c)
    end

    def apply(c)
      @reply = STDIN.getch
      while @reply != "y" && @reply != "n"
        puts describe(c)
        @reply = STDIN.getch
      end
    end

    def verify(c)
      @reply == "y"
    end
  end

  class Expect
    def initialize(msg, &block)
      @msg = msg
      @block = block
    end

    def describe(c)
      "Expect condition: #{@msg}"
    end

    def skip_if(c)
    end

    def apply(c)
      @result = @block.call(c)
    end

    def verify(c)
      @result
    end
  end
end

def self.change(change_id)
  c = Change.new(change_id)
  yield c if block_given?
  c
end

# export GITLAB_API_PRIVATE_TOKEN=glpat-REDACTED
# export GITLAB_API_ENDPOINT=https://gitlab.com/api/v4
