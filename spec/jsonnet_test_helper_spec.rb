# Of course, a test to test the test matcher

require 'spec_helper'

describe 'Jsonnet Matcher' do
  describe 'render_jsonnet' do
    it 'supports hash matching' do
      matcher = render_jsonnet({'a' => 'hello'})
      result = matcher.matches?(
        <<~JSONNET.strip
          local hello = "he" + "llo";
          {
            a: hello
          }
        JSONNET
      )
      expect(result).to be(true)
      expect(matcher.description).to eql('render jsonnet successfully')
    end

    it 'supports string matching' do
      matcher = render_jsonnet('hello')
      result = matcher.matches?(
        <<~JSONNET.strip
          local hello = "he" + "llo";
          hello
        JSONNET
      )
      expect(result).to be(true)
      expect(matcher.description).to eql('render jsonnet successfully')
    end

    it 'supports another expectation' do
      matcher = render_jsonnet(a_hash_including({ 'a' => 'hello' }))
      result = matcher.matches?(
        <<~JSONNET.strip
          {
            a: 'hello',
            b: [1, 2, 3]
          }
        JSONNET
      )
      expect(result).to be(true)
      expect(matcher.description).to eql('render jsonnet successfully')
    end

    it 'supports nested expectations' do
      matcher = render_jsonnet do |data|
        expect(data['a']).to eql('hello')
        expect(data['b']).to include(1)
      end
      result = matcher.matches?(
        <<~JSONNET.strip
          {
            a: 'hello',
            b: [1, 2, 3]
          }
        JSONNET
      )
      expect(result).to be(true)
      expect(matcher.description).to eql('render jsonnet successfully')
    end

    it 'renders jsonnet rendering failure' do
      matcher = render_jsonnet({'a' => 1})
      result = matcher.matches?(
        <<~JSONNET.strip
        {
          a = 1
        }
        JSONNET
      )
      expect(result).to be(false)
      expect(matcher.failure_message).to eql(
        <<~ERROR.strip
        Fail to render jsonnet content:
        ```
        {
          a = 1
        }
        ```
        ERROR
      )
    end

    it 'renders jsonnet assertion failure' do
      matcher = render_jsonnet({'a' => 1})
      result = matcher.matches?(
        <<~JSONNET.strip
          assert false : "A random assertion failure";
          {}
        JSONNET
      )
      expect(result).to be(false)
      expect(matcher.failure_message).to eql(
        <<~ERROR.strip
        Fail to render jsonnet content:
        ```
        assert false : "A random assertion failure";
        {}
        ```
        ERROR
      )
    end

    it 'renders error details intensively' do
      matcher = render_jsonnet({'a' => 'hi'})
      result = matcher.matches?(
        <<~JSONNET.strip
          local hello = "he" + "llo";
          {
            a: hello
          }
        JSONNET
      )
      expect(result).to be(false)
      expect(matcher.failure_message).to eql(
        <<~ERROR.strip
       Jsonnet rendered content does not match expectations:

       Jsonnet Content:
       ```
       local hello = "he" + "llo";
       {
         a: hello
       }
       ```

       Jsonnet compiled data:
       ```
       {"a"=>"hello"}
       ```

       Expectations:
       {"a"=>"hi"}
       ERROR
      )
    end
  end

  describe 'reject_jsonnet' do
    it 'supports compiling failure' do
      matcher = reject_jsonnet(/failed to compile/i)
      result = matcher.matches?(
        <<~JSONNET.strip
          {
            a = 1
          }
        JSONNET
      )
      expect(result).to be(true)
      expect(matcher.description).to eql('reject jsonnet content with reason: /failed to compile/i')
    end

    it 'supports jsonnet assertions' do
      matcher = reject_jsonnet(/random assertion failure/i)
      result = matcher.matches?(
        <<~JSONNET.strip
          assert false : "A random assertion failure";
          {}
        JSONNET
      )
      expect(result).to be(true)
      expect(matcher.description).to eql('reject jsonnet content with reason: /random assertion failure/i')
    end

    it 'renders errors if jsonnet compiles successfully' do
      matcher = reject_jsonnet(/failed to compile/i)
      result = matcher.matches?(
        <<~JSONNET.strip
          {
            a: 1
          }
        JSONNET
      )
      expect(result).to be(false)
      expect(matcher.failure_message).to eql('Jsonnet content renders successfully. Expecting an error!')
    end

    it 'renders errors if the error does not match' do
      matcher = reject_jsonnet(/another assertion/i)
      result = matcher.matches?(
        <<~JSONNET.strip
          assert false : "A random assertion failure";
          {}
        JSONNET
      )
      expect(result).to be(false)
      expect(matcher.failure_message).to match(/Jsonnet error does not match/i)
    end
  end
end
