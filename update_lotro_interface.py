import httpx
import requests
import os

# Get the pasword from github secret
try:
    MD5PASSWORD = os.environ["MD5PASSWORD"]
except KeyError:
    raise Exception("Secret password not available!")

try:
    REPO_URL = os.environ["REPO_URL"]
except KeyError:
    REPO_URL = "https://github.com/Dromo"

# Get the update version
try:
    update = os.environ['UPDATE']
except KeyError:
    raise Exception("Update variable not available!")

# Login lotrointerface.com
with httpx.Client() as client:
    post_data = {
        "vb_login_username": "drono",
        "do": "login",
        "vb_login_md5password": MD5PASSWORD,
    }
    login_response = client.post('https://www.lotrointerface.com/forums/login.php', data=post_data)

    # Succesfully logged in lotrointerface
    if login_response.status_code == 200:
        # get the zip file from the newly created release
        zip_url = REPO_URL+'/Pets/releases/download/'+update+'/Pets_'+update+'.zip'
        response = requests.get(zip_url)
        if response.status_code != 200:
            raise Exception("Failed to fetch zip")
        # setup lotrointerface edit form values
        files = {
            'replacementfile': ('Pets_'+update+'.zip', response.content, 'application/zip')
        }
        data = {
            'id': '1021',
            'op': 'editfile',
            'type': '1',
            'ftitle': 'Pets '+update,
            'version': update[1:],
            'fileaction': 'replace', # or 'keep'
        }
        # get and convert Release.md from github syntax to lotrointerface syntax
        raw_url = REPO_URL+'/Pets/raw/master/Release.md'
        response = requests.get(raw_url)
        if response.status_code == 200:
            content = response.text
            content = content.replace(" *","[*]")
            content = content.replace("[Full changelog]","[/LIST][Full changelog]")
            content = content.replace("[*]","[LIST]\n[*]",1)
            content = content.replace("* ","")
            content = content.replace("[Full changelog](Changelog.md)", '[URL="https://github.com/Dromo/Pets"]github[/URL] [URL="https://github.com/Dromo/Pets/blob/master/Changelog.md"]full changelog[/URL]')
            data['message'] = content
        else:
            raise Exception("Failed to fetch Release.md")
        raise Exception("Upload OK") # Testing purpose to prevent actual upload to lotrointerface, remove in live version
        edit_url = 'https://www.lotrointerface.com/downloads/editfile.php'

        # attempt to edit description and uplaod to lotrointerface
        response = client.post(edit_url, data=data, files=files)

        if response.status_code == 200:
            print("Upload successful!")
        else:
            raise Exception(f"Upload failed with status code {response.status_code}")
    else:
        raise Exception("Login failed.")
