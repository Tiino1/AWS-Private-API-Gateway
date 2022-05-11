import urllib.request

def handler(event, context):
    URL_LIST = [
        #TODO
        # {api gateway stage invocation url} 
        # {api gateway stage invocation url through VPC endpoint}
        # {custom dns name with route53} 
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
