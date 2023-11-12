import random
from transliterate import translit, get_available_language_codes

def generate_username(name, middlename):
    
    num_of_middle_name = random.randint(1, len(middlename))
    
    tname = translit(name, 'ru', reversed=True)
    ttname = tname.replace("'", "")

    tmiddlename = translit(middlename, 'ru', reversed=True)

    username = ttname.lower() + tmiddlename[0:num_of_middle_name].lower() + str(random.randint(0,99))

    return username
    