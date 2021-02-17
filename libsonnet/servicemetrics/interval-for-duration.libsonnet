{
  intervalForDuration(duration)::
    if duration == '30m' || duration == '6h' then
      '2m'
    else
      '1m',
}
