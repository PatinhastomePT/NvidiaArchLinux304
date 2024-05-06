#!/usr/bin/env bash
#===========================================
#script pra instala o driver nvidia 304.137 
#feito por Flydiscohuebr
#===========================================

#testes
#Verificando se e ROOT!
#==========================
[[ "$UID" -ne "0" ]] || { echo -e "Execute sem permissao root" ; exit 1 ;}
#==========================

#verificando se tem interwebs
#=====================================================
if ! wget -q --spider www.google.com; then
    echo "Não tem internet..."
    echo "Verifique se o cabo de rede esta conectado."
    exit 1
fi
#=====================================================

#makepkg reset
#
cd $PWD/pacotes
cd lib32-nvidia-304xx-utils/
sudo rm -r pkg/ src/ *.zst
cd ../linux515-nvidia-304xx/
sudo rm -r pkg/ src/ *.zst
cd ../nvidia-304xx-utils/
sudo rm -r pkg/ src/ *.zst
cd ../../
#

#identificando se o linux-headers esta instalado
#
pacman -Q linux-headers &> /dev/null
if [ ! $? -eq 0 ]; then
    echo "O pacote linux-headers nao foi detectado"
    echo "Instalando agora"
    sudo pacman -S --needed linux-headers
    echo 'Rode o instalador novamente'
    exit 1
fi

#
#identificando se e o endeavourOS
#
#DISTRONAME=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
#if [[ ${DISTRONAME} = "EndeavourOS"* ]]; then
#    echo -e "EndeavourOS Detectado \nRemovendo pacotes conlfitantes antes da instalacao"
#    sudo pacman -R lightdm-slick-greeter eos-lightdm-slick-theme
#fi
#

echo '
-----------------------------------------------------------------------
Instalador nao oficial do driver nvidia 304.137
by: Flydiscohuebr
qualquer erro ou problema durante a instalação envie uma mensagem no meu telegram
Telegram: @Flydiscohuebr
ou no comentario do video correspondente
-----------------------------------------------------------------------
'

echo '
IMPORTANTE IMPORTANTE IMPORTANTE IMPORTANTE

responda sim/yes S/Y a todas as perguntas do pacman a seguir caso contrario a instalação pode falhar

Testado no kernel 6.5 (acima dessa verção nao garanto sucesso na instalação)

IMPORTANTE IMPORTANTE IMPORTANTE IMPORTANTE
'
read -p "aperte enter para continuar ou ctrl+c para sair "

# isso vai ajudar a galera que não olha a descrição do video
if [ "$XDG_CURRENT_DESKTOP" = "XFCE" ]; then
    xfconf-query -c xfwm4 -p /general/vblank_mode -s xpresent
fi

#pacotes necessarios
sudo pacman -S --needed git gtk2 base-devel

#pacotes conflitantes
sudo pacman -Rc xf86-input-wacom
sudo pacman -Rc xf86-video-fbdev

#instalando xorg
cd $PWD/pacotes/xorg
sudo pacman -U -d xorg-server1.19-*
#downgrade libinput para funcionar teclado e mouse
sudo pacman -U xf86-input-libinput-*
cd ../

#instalando os bagui da nvidia agr
#nvidia-304xx-utils
cd nvidia-304xx-utils
makepkg -si
cd ../
#linux515-nvidia-304xx
cd linux515-nvidia-304xx
makepkg -si
cd ../
#lib32-nvidia-304xx-utils
cd lib32-nvidia-304xx-utils
makepkg -si
cd ../

#criando o xorg.conf e movendo pra /etc/X11/xorg.conf.d
sudo nvidia-xconfig -o "/etc/X11/xorg.conf.d/20-nvidia.conf" --composite --no-logo
sudo sed -i /'Section "Files"'/,/'EndSection'/s%'EndSection'%"\tModulePath \"/usr/lib64/nvidia/xorg\" \nEndSection"%g /etc/X11/xorg.conf.d/20-nvidia.conf
sudo sed -i /'Section "Files"'/,/'EndSection'/s%'EndSection'%"\tModulePath \"/usr/lib64/xorg/modules\" \nEndSection"%g /etc/X11/xorg.conf.d/20-nvidia.conf

#colocando nouveau e seus amigos na blacklist
sudo cp blacklist_nouveau.conf /usr/lib/modprobe.d/

#Reinstalando os pacotes removidos anteriormente
#
#DISTRONAME=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
#if [[ ${DISTRONAME} = "EndeavourOS"* ]]; then
#    echo -e "EndeavourOS Detectado \nReinstalando os pacotes removidos anteriormente"
#    sudo pacman -S lightdm-slick-greeter eos-lightdm-slick-theme
#fi

#adcionando nomodeset
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& nomodeset/' /etc/default/grub
sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT='[^']*/& nomodeset/" /etc/default/grub
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& nvidia_drm.modeset=1/' /etc/default/grub
sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT='[^']*/& nvidia_drm.modeset=1/" /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

#mkinitcpio
pacman -Q dracut &> /dev/null
if [ $? -eq 0 ]; then
    echo "Dracut detectado"
    sudo dracut --force /boot/initramfs-linux.img
    sudo dracut -N --force /boot/initramfs-linux-fallback.img
else
    sudo mkinitcpio -p linux
fi

echo '
Aparentemente foi tudo instalado com sucesso
reinicie o computador agora
qualquer coisa
Telegram: @Flydiscohuebr
ou escreva um comentario no video que vc baixou isso :)
'
echo '
Agora voce precisa impedir o xf86-input-libinput de ser atualizado
caso contrario o teclado e mouse vai parar de funcionar
voce pode impedir a atualizacao de um pacote descomentando a linha IgnorePkg no arquivo /etc/pacman.conf
e adcione na frente do " = " o nome do pacote 
ficando assim

IgnorePkg = xf86-input-libinput
'
#echo "
#ou usando esse comando
#sudo sed -i 's/#IgnorePkg   =/IgnorePkg = xf86-input-libinput/g' /etc/pacman.conf
#OBS: se voce ja tiver outros pacotes adicionados a IgnorePkg recomendo fazer isso manualmente ao invez de usar o comando
#"
