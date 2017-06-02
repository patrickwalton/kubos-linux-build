###############################################
#
# KubOS Command and Control Service
#
###############################################
UPDATE_DUMMY = $(shell kubos update) #unused dummy variable to run update before getting the version...
KUBOS_COMMAND_AND_CONTROL_VERSION = $(shell kubos versions 2>&1 | grep recent | awk '{print $$7}')
KUBOS_COMMAND_AND_CONTROL_LICENSE = Apache-2.0
KUBOS_COMMAND_AND_CONTROL_LICENSE_FILES = LICENSE
KUBOS_COMMAND_AND_CONTROL_SITE = git://github.com/kubostech/kubos
# The path to the command-and-control module in the kubos repo
KUBOS_REPO_COMMAND_AND_CONTROL_PATH = cmd-control-daemon
KUBOS_REPO_COMMAND_AND_CONTROL_CLIENT_PATH = cmd-control-client
KUBOS_REPO_COMMANDS_LIBRARY_PATH = commands
# The path from the command-and-control module to the build artifact directory
KUBOS_ARTIFACT_BUILD_PATH = build/kubos-linux-isis-gcc/source


#Use the Kubos SDK to build the command-and-control application
define KUBOS_COMMAND_AND_CONTROL_BUILD_CMDS
	cd $(@D) && \
	./tools/kubos_link.py --sys --app $(KUBOS_REPO_COMMAND_AND_CONTROL_PATH) && \
	cd $(@D)/$(KUBOS_REPO_COMMAND_AND_CONTROL_PATH) && \
	PATH=$(PATH):/usr/bin/iobc_toolchain/usr/bin && \
	kubos -t kubos-linux-isis-gcc build


	echo "Building the library"
	cd $(@D) && \
	./tools/kubos_link.py --sys --app $(KUBOS_REPO_COMMANDS_LIBRARY_PATH) && \
	cd $(@D)/$(KUBOS_REPO_COMMANDS_LIBRARY_PATH) && \
	PATH=$(PATH):/usr/bin/iobc_toolchain/usr/bin && \
	kubos -t kubos-linux-isis-gcc build


	echo "Building the client"
	cd $(@D) && \
	./tools/kubos_link.py --sys --app $(KUBOS_REPO_COMMAND_AND_CONTROL_CLIENT_PATH) && \
	cd $(@D)/$(KUBOS_REPO_COMMAND_AND_CONTROL_CLIENT_PATH) && \
	PATH=$(PATH):/usr/bin/iobc_toolchain/usr/bin && \
	kubos -t kubos-linux-isis-gcc build

endef


#Install the application into the rootfs file system
define KUBOS_COMMAND_AND_CONTROL_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/sbin
	mkdir -p $(TARGET_DIR)/home/system/var/log/
	$(INSTALL) -D -m 0755 $(@D)/$(KUBOS_REPO_COMMAND_AND_CONTROL_PATH)/$(KUBOS_ARTIFACT_BUILD_PATH)/cmd-control-daemon \
		$(TARGET_DIR)/usr/sbin/kubos-command-and-control

	echo "Installing the Command Library"
	mkdir -p $(TARGET_DIR)/usr/local/kubos
	$(INSTALL) -D -m 0755 $(@D)/$(KUBOS_REPO_COMMANDS_LIBRARY_PATH)/$(KUBOS_ARTIFACT_BUILD_PATH)/commands \
		$(TARGET_DIR)/usr/local/kubos/core
	mkfifo  $(TARGET_DIR)/usr/local/kubos/client-to-server
	mkfifo  $(TARGET_DIR)/usr/local/kubos/server-to-client

	echo "Installing the Client"
	mkdir -p $(TARGET_DIR)/usr/bin
	$(INSTALL) -D -m 0755 $(@D)/$(KUBOS_REPO_COMMAND_AND_CONTROL_CLIENT_PATH)/$(KUBOS_ARTIFACT_BUILD_PATH)/cmd-control-client \
		$(TARGET_DIR)/usr/bin/c2
endef

#Install the init script
define KUBOS_COMMAND_AND_CONTROL_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_KUBOS_LINUX_PATH)/package/kubos-command-and-control/kubos-command-and-control \
	$(TARGET_DIR)/etc/init.d/S$(BR2_KUBOS_COMMAND_AND_CONTROL_INIT_LVL)kubos-command-and-control
endef

kubos-command-and-control-fullclean: kubos-command-and-control-clean-for-reconfigure kubos-command-and-control-dirclean
	rm -f $(BUILD_DIR)/kubos-command-and-control-$(KUBOS_COMMAND_AND_CONTROL_VERSION)/.stamp_downloaded
	rm -f $(DL_DIR)/kubos-command-and-control-$(KUBOS_COMMAND_AND_CONTROL_VERSION).tar.gz


kubos-command-and-control-clean: kubos-command-and-control-clean-for-rebuild
	cd $(BUILD_DIR)/kubos-command-and-control-$(KUBOS_COMMAND_AND_CONTROL_VERSION)/$(KUBOS_REPO_COMMAND_AND_CONTROL_PATH); kubos clean
	cd $(TARGET_DIR)/etc/init.d; rm -f S*kubos-command-and-control

$(eval $(generic-package))
