# example of python code to load alcohol.txt

import re

with open('alcohol_by_state.txt', 'r') as f:
    lines = f.readlines()

# remove whitespace characters like `\n` at the end of each line
lines = [x.strip() for x in lines] 

# state names 
def isState(f):
    p = re.compile('([A-Z].*)', re.IGNORECASE)
    result = p.match(f)
    if result: return result.group()
    #if result: return true

# remove .... and replace spaces with commas
def line2csv(f):
    # remove ' ..... '
    f = re.sub(r" ?\.+ ", " ", f)
    # replace spaces with comma
    return re.sub(r" ", ",", f)

for line in lines: 
    #print("line: " + line)
    newState = isState(line)
    if newState: 
        state = newState
    else:
        # set vars
        vars = line2csv(line)
        print('{state},{vars}'.format(state=state, vars=vars))
    
