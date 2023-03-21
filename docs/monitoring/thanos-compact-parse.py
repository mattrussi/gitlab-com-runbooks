#!/usr/bin/env python

import sys
import re
import time

# This script expects piped input from a log source
# eg. kubectl -n thanos logs {compactor pod} | ./thanos-compact-parse.py

text = '\n'.join(sys.stdin.readlines())
results = re.findall("ulid: ([^,]+), mint: ([^,]+), maxt: ([^,]+), range: ([^>]+)", text)
tuples = [x for x in results]

# We assume that sequential entries are 'overlapping'
# But lets just quickly assert that we've got an even number
if len(tuples) % 2 != 0:
    print("Uneven number of blocks!")
    sys.exit(1)

def to_obj(t):
    obj = type('',
               (object,),{
                "ulid": t[0],
                "tmin": int(t[1]),
                "tmax": int(t[2]),
                "range": t[3],
                "range_h": int(t[3].split('h')[0])
                   })()

    return obj

one_month_in_milliseconds = 2630000 * 1000
def is_older_than_m(block, months):
    # How many milliseconds are in the given number of months
    ms = months * one_month_in_milliseconds

    # time.time() returns seconds, so we multiply by 1000.
    # we add the reference time to the start time of the block
    # then compare that and see if its past whatever the time is now,
    # if it is, then we know that its less than x months old.
    return block.tmin + ms < time.time() * 1000 


commands = []
for idx in range(0, len(tuples), 2):
    b1=to_obj(tuples[idx])
    b2=to_obj(tuples[idx + 1])

    if b1.range_h < b2.range_h:
        smallest = b1
    else:
        smallest = b2

    if is_older_than_m(smallest, 6):
        # block is old, so we follow https://ops.gitlab.net/gitlab-com/runbooks/blob/master/docs/monitoring/thanos-compact.md#if-the-blocks-are-older-than-6-months
        commands.append(f"gsutil rm -r gs://gitlab-gprd-prometheus/{smallest.ulid}")
    else:
        commands.append(f"""/opt/prometheus/thanos/thanos tools bucket mark \
--objstore.config-file=/opt/prometheus/thanos/objstore.yml \
--marker=no-compact-mark.json \
--details='ISSUE LINK HERE' \
--id=\"{smallest.ulid}\" """)

print("""CONTEXT:""")
[print(t) for t in tuples]

print("""COMMANDS""")
[print(c) for c in commands]

