set -e -x
sudo mkdir /selinux-modules
sudo cp ./dependencies/allow-system-manager.te /selinux-modules
sudo checkmodule -M -m -o /selinux-modules/allow-system-manager.mod /selinux-modules/allow-system-manager.te 
sudo semodule_package -o /selinux-modules/allow-system-manager.pp -m /selinux-modules/allow-system-manager.mod 
sudo semodule -i /selinux-modules/allow-system-manager.pp
