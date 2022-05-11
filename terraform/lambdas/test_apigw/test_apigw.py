import urllib.request

def handler(event, context):
    URL_LIST = [
        # TODO
        # There are 2 (+ 1 bonus with route 53) urls to test
    ]

    for url in URL_LIST:
        print('---')
        try:
            response = urllib.request.urlopen(url, timeout=1)
            print("SUCCESS -", url)
            print(response.read())
        except Exception as e:
            print("ERROR    -", url)
            print(e)

    return {
        "statusCode": 200,
        "body": "empty"
    }
