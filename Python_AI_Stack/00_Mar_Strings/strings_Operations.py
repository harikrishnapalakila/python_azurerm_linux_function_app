#Step: Write a program for Adding of 2 Strings

print("#############>>>> Add / Addition of 2 Strings <<<#################")
print("Addition Program has been Started........!!!")

name1  = "hari"
name2 = "krishna"
adding_of_2_strings = name1 + name2    # harikrishna - output value -- syntax 
print(adding_of_2_strings)

print("hari")
print("krishna")
print("hari")
print("krishna")

print(name1 + name2)  #lambda --> lamda expres:result   #lambda a,b:a+b
print()
print()
print()
print()

# can we add string with integer ...? : yes ... We can 
username = "harikrihna"
password = "harikrishna1234"
emi      = "onelack"  #- [0,1,2,3,4,5,6,7]
print(emi[3::-1])   # n-1
#newpassword = int("harikrishna1234")
print()
print()

for i in emi:
    print("we are looping emi....!!!", i )
print()
print()
emi2      = "onelack"  #- [0,1,2,3,4,5,6,7]
#bal = [(lambda emi3: print(i)) for i in emi2]
bal = [(lambda emi3, i=i: print(i)) for i in emi2]
for f in bal:
    f(None)

bal2 = list(map(lambda i: i, emi2))
print(bal2)

print(username)
print(password)
print(username + password)

#reversed[::-1] - slice function
#for loop

####################### 19/03/2026 ####################
print("###############  Lambda Function configuration has started over here..........!!!")
print()
print()

lambda_error = lambda n: [print(i) for i in range(n)]
lambda_error(10)

def for_function():
    print("Using for-loop to Stdout Ten cars.........!!")
cars=10
for car in range(cars):
    print(car)
for_function()
for_function()
for_function()

print("Using Lambda to print ten cars .........!!")
tencars = lambda cars:[print(car) for car in range(cars)]
tencars(10)

####################### 19/03/2026 ####################

print("EMI - Payment details ........!!!")
emis=10
for emi in range(emis):
   print("Number of Emi's paid   : ",emi)



############ Convert to lambda function ##########
print("############ Convert to lambda function ##########")
print()
print()
emi_pending = lambda emis : [print("Number of Emi's paid   : ",emi) for emi in range(emis)]
emi_pending(10)

#for(i=0;i<10;i++) {}

funs = [(lambda x,i=i: x*i ) for i in range(5)]
print(funs[2](10))
print(funs[3](10))
print(funs[4](10))
print(funs[1](10))
print(funs[0](10))
#print(funs[6](10))

emi1,emi2,emi3=input("Enter your emi amount : ").split(" ")
print(("Thanks for EMI Payment ...!!", emi1,emi2,emi3))

########################## EOD ##########################
#class non-globa():

def reuse():
    print("############## Reuse below code .........!!")
    n=20 
    names=["hari","krishna","kittu"] 
    salarys=["10000","20000","30000"] 
    for sid in range(n): 
        print(f"{sid } |") 
        for name in names:
            print(f"{ name }|") 
            for salary in salarys:
                print(salary)  

reuse()



print("########################## EOD ##########################")



reuse()

listhari = [1,2,3,4,5,6,7,8,9,10,10000,10000,20000,20000]
list_update=list(set(listhari))
print(list_update)

print()
print()
resource_group_name = "RG-dev-azureopenai-service"
azureopenai_endpoint = "https://adaptiveRAGSetup.azureopenai.com"
print(f" We're working on Duplicate Resource details for azure cloud infra and checking azure billing in Thousand + lacks level for - {resource_group_name}-{azureopenai_endpoint}")
print()
print()
azure_resource_numbers=[1,2,3,4,5,6,6,7,7,7,8,9,10,10,1000,1000,20000,20000,"hari","krishna","hari","krishna"]
unique_list = []
#output = lambda if i not in listhari1 unique_list.append(i): [print(i) for i in listhari1]
for i in azure_resource_numbers:
    if i not in unique_list:
        unique_list.append(i)
print(unique_list)


print()
print()

print("########### Azure cloud Infra checking for azure Resource + Azure OpenAI + Azure Billing Details using python programming ###################")

print()
print()
regions = ["centralus","centralus","eastus","eastus","southcentralus","southcentralus","northcentralus","northcentralus"]
unique_regions = []
for region in regions:
    print(f" Need to find unique region for azureopen ai services from {regions}-{unique_regions}")
    if region not in unique_regions:
        unique_regions.append(region)
print()
print()
print(f"all regions list : {regions}")
print(f"New Regions list : {unique_regions}")


