#Developed by Bilal Javed
def pars(obj_pars,key_pars):
    key_pars=key_pars.split('/')
    temp = obj_pars[key_pars[0]]
    for i in range(1,len(key_pars)):
        temp = temp[key_pars[i]]
    
    return temp
#obj_1= {"a":{"b":{"c":"d"}}}
#key_1="a/b/c"
obj_1= {"x":{"y":{"z":"a"}}}
key_1="x/y/z"
result = pars(obj_1,key_1)
print(result)