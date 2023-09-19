import subprocess

def trace_route(ip_address):
    command = "traceroute -n {}".format(ip_address)
    result = subprocess.getoutput(command)
    return result

def main():
    url = "https://www.cloudflare.com/ips-v4"
    
    # 通过curl命令获取Cloudflare IP段列表
    command = "curl {}".format(url)
    output = subprocess.getoutput(command)
    ip_ranges = output.strip().split("\n")
    
    for ip_range in ip_ranges:
        print("Tracing route for IP range: {}".format(ip_range))
        result = trace_route(ip_range)
        print(result)
        print("=" * 50)

if __name__ == "__main__":
    main()
