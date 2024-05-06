#!/bin/bash
# !!! ANVÄND SUDO !!!!
# Studiegrupp 4 SSH / Användarhantering på Linux.
# Meny val 1 = Säker SSH Config
#       Försöker patcha SSH genom apt.
#       Lägger till en säker SSH Config fil i /etc/ssh byter ut sshd_config.
#       Aktiverar UFW blockar allt utom ssh porten.
#       Lägger till gruppen SysAdmin och ger den sudo rättigheter.
#       Startar om SSHD genom systemctl restart sshd.
# Meny val 2 = Lägga till användare med SSH rättighet.
#       Frågar efter Användarnamn / Email för att lägga till rätt användare.
#       Lägger till användaren i rätt grupp för att kunna använda SSH.

# Meny val 3 = Övervaka auth.log för misslyckades lösenords försök genom ssh.
# Meny val 0 = Avsluta scriptet.

# Funktion för att utföra automation för sshd config.
sshd_config() {
    clear
        echo "Kör SSH Konfig..."
        # Updaterar och installerar SSH Server ifall den ej är installerad.
        echo "Updaterar OpenSSH-server..."
        apt update && apt install -y openssh-server
        # Gör backup på den vanliga ssh configen.
        echo "Skapar Backup på din sshd_config till sshd_config.backup"
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
        # Kopiera en säker sshd konfiguration till /etc/ssh.
        echo "Kopierar säker sshd_config till /etc/ssh/sshd_config..."
        cp sshd_config /etc/ssh/sshd_config
        # Kopiera banner till /etc/ssh
        echo "Kopierar banner.txt till /etc/ssh"
        cp banner.txt /etc/ssh/
        # Tillåt SSH port
        echo "Tillåter tcp uppkoppling på port 33556 genom UFW"
        ufw allow 33556/tcp
        # Blockera all inkommande trafik
        echo "Blockerar all inkommande trafik.(UFW)"
        ufw default deny incoming
        # Tillåt all utgående trafik
        echo "Tillåter all utgående trafik. (UFW)"
        ufw default allow outgoing
        # Startar UFW automatiskt genom att ge den 'yes' som standard.
        echo "Startar UFW..."
        sudo sh -c 'yes | ufw enable'
        # Skapa gruppen SysAdmin
        echo "Skapar gruppen SysAdmin om den inte redan finns..."
        groupadd -f SysAdmin
        # Lägg till sudo privilegier för medlemar av SysAdmin gruppen
        echo "Ser till så sudo är tillgängligt för medlemmar av SysAdmin gruppen..."
        # Lägger till en sudo-åtkomstregel för gruppen SysAdmin i filen /etc/sudoers.d/SysAdmin
        echo "%SysAdmin ALL=(ALL) ALL" | sudo EDITOR='tee -a' visudo -f /etc/sudoers.d/SysAdmin
        # Starta om SSH service
        echo "Startar om SSH daemon för att nya inställningar ska gälla."
        systemctl restart sshd
        echo "SSH konfiguration färdig."
        # Återgår till menyn
        menu
}

#Funktion för att lägga till en användare med ssh behörighet och ett starkt lösenord.

add_ssh_user() {
    clear
        echo "Skriv in användarnamn:"
        read user
        echo "Skriv in email:"
        read email

        # Generera random lösenord
        password=$(openssl rand -base64 16)

        # Lägg till användare med specifikt användarnamn och email, samt lägg till random lösenord
        adduser $user --gecos "$email" --disabled-password
        echo "$user:$password" | chpasswd

        # Lägg till användare till 'SysAdmin' grupp.
        echo "Lägger till $user i grupp SysAdmin"
        usermod -aG SysAdmin $user

        # Skriv ut det genererade lösenordet för användaren.
        echo "Användare: $user"
        echo "Email: $email"
        echo "Lösenord: $password"
        echo "Användare $user färdig."
        # Tillbaka till menyn
        menu
}


#Funktion för att övervaka SSH.
ssh_surveillance() {
    clear
    echo "Kontinuerligt övervakar auth.log efter inloggningsförsök genom SSH..."

    # Huvudloop för att övervaka misslyckade inloggningsförsök
    while true; do
        # Hämtar information om misslyckade login försök med fel lösenord från auth.log
        failed_logins=$(grep 'sshd.*Failed password' /var/log/auth.log)

        # Skriver ut misslyckade login försök
        if [ -n "$failed_logins" ]; then
            clear
            echo "Misslyckade SSH login försök:"
            echo "$failed_logins"
            echo "Tryck på 'q' för att avsluta."
        else
            echo "Inga misslyckade SSH login försök."
        fi

        # Läs in en knapptryckning från användaren
        # Vänta i 10 sekunder på inmatning
        read -t 10 -n 1 key

        # Om användaren trycker på "q" avslutas loopen
        if [[ $key == "q" ]]; then
            echo "Avbröt scriptet."
            break
        fi
    done
    clear
    menu
}

#Funktion för själva scriptets meny.
# Genom en case där olika siffror kör olika funktioner.
menu() {
    echo "Meny:"
    echo "1: Konfigurera Säker SSH"
    echo "2: Lägg till SSH Användare"
    echo "3: Övervaka misslyckade SSH login försök"
    echo "0: Avsluta"

# Läser in genom read till variablen choice där värdet på variablen choice väljer vilken funktion som ska köras.
    read -p "Skriv in ditt val: " choice

    case $choice in
        1) sshd_config ;;
        2) add_ssh_user ;;
        3) ssh_surveillance ;;
        0) exit ;;
# Ifall det inte är någon av 1, 2 ,3 eller 0 som skrivits så körs denna rad som felhantering.
        *) clear && echo "$choice är inte ett korrekt val" && menu ;;
    esac
}

echo "!!! Behöver SUDO rättigheter för att fungera !!!"

menu