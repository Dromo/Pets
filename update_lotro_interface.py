import httpx
import requests
import os

try:
    MD5PASSWORD = os.environ["MD5PASSWORD"]
except KeyError:
    raise Exception("Secret password not available!")

with httpx.Client() as client:
    post_data = {
        "vb_login_username": "drono",
        "do": "login",
        "vb_login_md5password": MD5PASSWORD,
    }
    login_response = client.post('https://www.lotrointerface.com/forums/login.php', data=post_data)

    if login_response.status_code == 200:
        files = {
            'replacementfile': ('Pets_U44.2.zip', open('/home/ondro/Downloads/Pets_U44.2.zip', 'rb'), 'application/zip')
        }
        data = {
            'id': '1021',
            'op': 'editfile',
            'type': '1',
            'ftitle': 'Pets U44.2',
            'version': '44.2',
            'fileaction': 'replace',
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
            print(content)

        edit_url = 'https://www.lotrointerface.com/downloads/editfile.php'

        response = client.post(edit_url, data=data, files=files)

        if response.status_code == 200:
            print("Upload successful!")
        else:
            print(f"Upload failed with status code {response.status_code}")
    else:
        print("Login failed.")
