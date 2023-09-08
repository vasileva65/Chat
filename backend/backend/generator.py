import random

def generate_username(name, middlename):
    
    num_of_middle_name = random.randint(1, len(middlename))
          
    username = name.lower() + middlename[0:num_of_middle_name].lower() + str(random.randint(0,99))

    return username





    