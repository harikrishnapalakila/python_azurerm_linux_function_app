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



