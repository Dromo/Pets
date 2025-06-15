import httpx
import requests
import os

try:
    MD5PASSWORD = os.environ["MD5PASSWORD"]
except KeyError:
    raise Exception("Secret password not available!")

try:
    update = os.environ['UPDATE']
except KeyError:
    raise Exception("Update variable not available!")

with httpx.Client() as client:
    post_data = {
        "vb_login_username": "drono",
        "do": "login",
        "vb_login_md5password": MD5PASSWORD,
    }
    login_response = client.post('https://www.lotrointerface.com/forums/login.php', data=post_data)

    if login_response.status_code == 200:
        zip_url = 'https://github.com/Dromo/Pets/releases/download/'+update+'/Pets_'+update+'.zip'
        response = requests.get(zip_url)
        if response.status_code != 200:
            raise Exception("Failed to fetch zip")
        files = {
            'replacementfile': ('Pets_'+update+'.zip', response.content, 'application/zip')
        }
        data = {
            'id': '1021',
            'op': 'editfile',
            'type': '1',
            'ftitle': 'Pets '+update,
            'version': update[1:],
            'fileaction': 'keep',
#            'fileaction': 'replace',
        }
        raw_url = "https://raw.githubusercontent.com/Dromo/Pets/refs/heads/master/Release.md"
        response = requests.get(raw_url)
        if response.status_code == 200:
            content = response.text
            content = content.replace(" *","[*]")
            content = content.replace("[Full changelog]","[/LIST][Full changelog]")
            content = content.replace("[*]","[LIST]\n[*]",1)
            content = content.replace("* ","")
            content = content.replace("[Full changelog](Changelog.md)", '[URL="https://github.com/Dromo/Pets"]github[/URL] [URL="https://github.com/Dromo/Pets/blob/master/Changelog.md"]full changelog[/URL]')
            data['message'] = content

        edit_url = 'https://www.lotrointerface.com/downloads/editfile.php'

        response = client.post(edit_url, data=data, files=files)

        if response.status_code == 200:
            print("Upload successful!")
        else:
            raise Exception(f"Upload failed with status code {response.status_code}")
    else:
        raise Exception("Login failed.")
