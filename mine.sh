#!/bin/bash
uninstall_amd_driver() {
	echo "Uninstalling driver"
	echo 'APT::Get::Assume-Yes "true";' >>/etc/apt/apt.conf.d/90assumeyes
	/usr/bin/amdgpu-uninstall
	rm /etc/apt/apt.conf.d/90assumeyes
	echo "Done!"
}

install_amd_driver() {
	AMD_DRIVER=$1
	AMD_DRIVER_URL=$2
	FLAGS=$3
	echo "Installing driver"
	echo "Downloading driver from "$AMD_DRIVER_URL/$AMD_DRIVER
	echo 'APT::Get::Assume-Yes "true";' >>/etc/apt/apt.conf.d/90assumeyes
	mkdir -p /tmp/opencl-driver-amd
	cd /tmp/opencl-driver-amd
	echo AMD_DRIVER is $AMD_DRIVER
	curl --referer $AMD_DRIVER_URL -O $AMD_DRIVER_URL/$AMD_DRIVER
	tar -Jxvf $AMD_DRIVER
	rm $AMD_DRIVER
	cd amdgpu-pro-*
	./amdgpu-install $FLAGS
	rm -rf /tmp/opencl-driver-amd
	echo ""
	echo "Driver installation finished."
	INSTALLED_DRIVERV=$(cd /home/docker/phoenixminer && ./PhoenixMiner -list | grep -m 1 "OpenCL driver version" | sed 's/OpenCL driver version: //g' | cut -c1-5)
	rm /etc/apt/apt.conf.d/90assumeyes
}

INSTALLED_DRIVERV=$(cd /home/docker/phoenixminer && ./PhoenixMiner -list | grep -m 1 "OpenCL driver version" | sed 's/OpenCL driver version: //g' | cut -c1-5)
if [[ "${INSTALLED_DRIVERV}" != "${DRIVERV}" ]]; then
	echo "Installed driver version (${INSTALLED_DRIVERV}) does not match wanted driver version (${DRIVERV})"
	echo "Installing AMD drivers v${DRIVERV}:"
	echo ""

	case $DRIVERV in

	0)
		uninstall_amd_driver
		echo "Skipping installation"
		;;

	18.20)
		uninstall_amd_driver
		install_amd_driver "amdgpu-pro-18.20-621984.tar.xz" "https://drivers.amd.com/drivers/linux/ubuntu-18-04" "--opencl=legacy,pal --headless"
		;;

	20.20)
		uninstall_amd_driver
		install_amd_driver "amdgpu-pro-20.20-1098277-ubuntu-20.04.tar.xz" "https://drivers.amd.com/drivers/linux" "--opencl=legacy,pal --headless --no-dkms"
		;;

	20.45)
		uninstall_amd_driver
		install_amd_driver "amdgpu-pro-20.45-1188099-ubuntu-20.04.tar.xz" "https://drivers.amd.com/drivers/linux" "--opencl=legacy,pal --headless --no-dkms"
		;;

	20.50)
		uninstall_amd_driver
		install_amd_driver "amdgpu-pro-20.50-1234664-ubuntu-20.04.tar.xz" "https://drivers.amd.com/drivers/linux" "--opencl=legacy,rocr --headless --no-dkms"
		;;
	*)
		INSTALLED_DRIVERV="No AMD Drivers Installed"
		;;
	esac

fi

echo "Project:      xmrig ${MINERV}"
echo "Author:       lnxd"
echo "Base:         Ubuntu 20.04"
echo "Target:       Unraid 6.9.0 - 6.9.2"
echo "Donation:     ${FEE} ${DONATE}%"
echo "Driver:       $INSTALLED_DRIVERV"
echo "OpenCL Path: "$(find / -name "/usr/lib/x86_64-linux-gnu/libOpenCL.so" 2>&1 | grep "libOpenCL.so")
echo ""
echo "Running xmrig with the following flags:"
echo "--url=${POOL} --coin=${COIN} --user=${WALLET}.${WORKER} --randomx-wrmsr=-1 --randomx-no-rdmsr ${ADDITIONAL}"
echo ""
cd /home/docker/xmrig-${FEE}
./xmrig --url=${POOL} --coin=${COIN} --user=${WALLET}.${WORKER} --donate-level=${DONATE} --randomx-wrmsr=-1 --randomx-no-rdmsr ${ADDITIONAL}
