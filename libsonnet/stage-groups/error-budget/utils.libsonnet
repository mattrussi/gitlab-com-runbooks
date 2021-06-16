local durationParser = import 'utils/duration-parser.libsonnet';

{
  budgetSeconds(slaTarget, range): (1 - slaTarget) * durationParser.toSeconds(range),
}
