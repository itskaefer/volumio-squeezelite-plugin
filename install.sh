## Squeezelite installation script
echo "Installing Squeezelite and its dependencies..."
INSTALLING="/home/volumio/squeezelite-plugin.installing"
PLUGIN_DIR="/data/plugins/audio_interface/squeezelite"

if [ ! -f $INSTALLING ]; then
  /bin/touch $INSTALLING

  if [ ! -d /opt/squeezelite ]; then
	dist=$(cat /etc/os-release | grep '^VERSION=' | cut -d '(' -f2 | tr -d ')"')
	arch=$(arch)
    variant=$(cat /etc/os-release | grep '^VOLUMIO_VARIANT=' | cut -d '=' -f2 | tr -d '"')
    
    if [ $dist = "buster" ]; then
      rm $PLUGIN_DIR/index.js
      mv $PLUGIN_DIR/index.js.volumio3 index.js
    fi

    # volumio minidsp distribution
    if ([ $dist = "jessie" ] || [ $dist = "buster" ]) && [ $variant = "minidspshd" ] && ( [ $arch = "armv6l" ] || [ $arch = "armv7l" ] || [ $arch = "aarch64" ] ); then
      echo "Using squeezelite 1.9.9 armel static architecture (detected minidsp SHD)"
      ln -fs $PLUGIN_DIR/known_working_versions/jessie/squeezelite-arm-minidspshd /opt/squeezelite
    # regular volumio2 distribution
    elif [ $dist = "jessie" ] && ( [ $arch = "armv6l" ] || [ $arch = "armv7l" ] || [ $arch = "aarch64" ] ); then
      echo "Using squeezelite 1.8.7 for compatibility reasons (detected Debian Jessie)"
	  ln -fs $PLUGIN_DIR/known_working_versions/jessie/squeezelite-armv6hf-volumio /opt/squeezelite
    # regular volumio3 distribution with 32bit arm cpu
	elif [ $dist = "buster" ] && ( [ $arch = "armv6l" ] || [ $arch = "armv7l" ] ); then
	  echo "Using squeezelite 1.9.9 for armhf architecture"
	  ln -fs $PLUGIN_DIR/known_working_versions/squeezelite-1.9.9.1392-armhf /opt/squeezelite
    # regular volumio3 distribution with 64bit arm cpu
	elif [ $dist = "buster" ] && ( [ $arch = "aarch64" ] ); then
	  echo "Using squeezelite 1.9.9 for aarch64 architecture"
	  ln -fs $PLUGIN_DIR/known_working_versions/squeezelite-1.9.9.1392-aarch64 /opt/squeezelite
    # regular volumio3 distribution with 64bit x86 cpu 
	elif [ $dist = "buster" ] && ( [ $arch = "x86_64" ] ); then
	  echo "Using squeezelite 1.9.9 for x86_64 architecture"
	  ln -fs $PLUGIN_DIR/known_working_versions/squeezelite-1.9.9.1392-x86_64 /opt/squeezelite
    # regular volumio3 distribution with 32bit x86 cpu
	elif [ $dist = "buster" ] && ( [ $arch = "i686" ] ); then
	  echo "Using squeezelite 1.9.9 for i686 architecture"
	  ln -fs $PLUGIN_DIR/known_working_versions/squeezelite-1.9.9.1392-i686 /opt/squeezelite
	fi

    # Fix executable rights
	chown volumio:volumio /opt/squeezelite
	chmod 755 /opt/squeezelite
		
	# activate default unit
	TMPUNIT="$PLUGIN_DIR/unit/squeezelite.service"
    cp $TMPUNIT-template $TMPUNIT
	chown volumio:volumio $TMPUNIT

    # set default values
	sed 's|${OUTPUT_DEVICE}|-o default|g' -i $TMPUNIT
	sed 's|${ALSA_PARAMS}|-a 80:4::|g' -i $TMPUNIT
    sed 's|${SERVER_PARAMS}|-s 127.0.0.1|g' -i $TMPUNIT

    
    if [ $variant = "minidspshd" ]; then
      pluginsPath="/data/plugins/audio_interface"
      
      # miniDSP needs special extra parameters
      rm $PLUGIN_DIR/config.json
      mv $PLUGIN_DIR/config_minidsp.json $PLUGIN_DIR/config.json
      
      # special functions for working remote buttons play,pause,next,previous are only working on the old volumio2 system for now
      if [ $dist = "jessie" ]; then 
        pluginInputs="/volumio/app/plugins/audio_interface/inputs/index.js"
        echo "Add special config for minidsp ..."
        cp $pluginsPath/squeezelite/config_minidsp.json $pluginsPath/squeezelite/config.json
        if [ $(grep -c "squeezelite" $pluginInputs ) -eq 0 ]; then
          sed -i "s/self.commandRouter.volumioToggle();/this.commandRouter.executeOnPlugin('audio_interface', 'squeezelite', 'pause');\n    self.commandRouter.volumioToggle();/g" $pluginInputs
          sed -i "s/self.commandRouter.volumioPrevious();/this.commandRouter.executeOnPlugin('audio_interface', 'squeezelite', 'previousSong');\n    self.commandRouter.volumioPrevious();/g" $pluginInputs
          sed -i "s/self.commandRouter.volumioNext();/this.commandRouter.executeOnPlugin('audio_interface', 'squeezelite', 'nextSong');\n    self.commandRouter.volumioNext();/g" $pluginInputs
        else
          echo "Plugin inputs already updated ..."
        fi
      fi
      echo "Fix permissions ..."
      chown -R volumio:volumio $pluginsPath/squeezelite
      sed 's|${NAME}|-n miniDSP-SHD|g' -i $TMPUNIT
      sed 's|${EXTRA_PARAMS}|-r 44100-196000 -R vE:::24|g' -i $TMPUNIT
    else
      sed 's|${NAME}|-n Volumio|g' -i $TMPUNIT
      sed 's|${EXTRA_PARAMS}||g' -i $TMPUNIT
    fi
		
	#mv $TMPUNIT /etc/systemd/system/squeezelite.service
    if [ -f /etc/systemd/system/squeezelite.service ]; then
      rm /etc/systemd/system/squeezelite.service
    fi
	ln -fs $PLUGIN_DIR/unit/squeezelite.service /etc/systemd/system/squeezelite.service
	systemctl daemon-reload
  else
    echo "Plugin already exists, not continuing."
  fi
	
	rm $INSTALLING

	# Required to end the plugin install
	echo "plugininstallend"
else
	echo "Plugin is already installing! Not continuing..."
fi
