import nmap

# Skapa ett nmap-objekt
nm = nmap.PortScanner()

# Ange IP-adress för skanningen
target_ip = '127.0.0.1'

# Starta en aggressiv Nmap-skanning för att identifiera öppna portar och få mer detaljerad information om servern
print("Startar aggressiv Nmap-skanning...")
nm.scan(hosts=target_ip, arguments='-A -sC -sV -p-')

# Hämta resultatet av Nmap-skanningen
scan_result = nm[target_ip]

try:
    # Skriv ut öppna portar på målsystemet
    open_ports = [port for port in scan_result['tcp'].keys() if scan_result['tcp'][port]['state'] == 'open']
    print("Öppna portar på målsystemet:")
    print(open_ports)

    # Kontrollera om det finns en SSH-port genom att söka efter namnet ssh.
    ssh_port = None
    for port in open_ports:
        if 'ssh' in scan_result['tcp'][port]['name'].lower():
            ssh_port = port
            break

    # Om en SSH-port hittades, skriv ut den och skanna efter sårbarheter
    if ssh_port:
        print(f"SSH-porten är öppen på port {ssh_port}.")
        print("Startar sårbarhetsskanning på SSH-porten...")
        nm.scan(hosts=target_ip, ports=str(ssh_port), arguments='--script vuln,exploit,vulners')
        ssh_scan_result = nm[target_ip]['tcp'][ssh_port]
        # Kontrollera om det finns rapporterade sårbarheter för SSH-porten
        if 'script' in ssh_scan_result and 'vuln,exploit,vulners' in ssh_scan_result['script']:
            print("Rapporterade sårbarheter på SSH-porten:")
            # Loopa igenom varje rapporterad sårbarhet och skriv ut dem
            for vulnerability in ssh_scan_result['script']['vuln,exploit,vulners']:
                print(vulnerability)
        else:
            print("Inga sårbarheter rapporterade på SSH-porten.")
    else:
        print("Ingen SSH-port hittades på målsystemet.")
except KeyError:
    print("Det finns ingen information om öppna portar i skanningssvaret.")

# Avsluta skanningen
print("Skanningen avslutad.")