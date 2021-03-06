# October 2016, Michael G Wiebe and Rahul Shenoy
#
# Copyright (c) 2016-2017 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'node_util'
require_relative 'logger'

module Cisco
  # Upgrade - node util class for upgrading Cisco devices
  class Upgrade < NodeUtil
    # Delete install logs from previous installation
    def self.clear_status
      config_set('upgrade', 'clear_status')
    end

    # Deletes 'image' from 'uri'
    def self.delete(image, uri='bootflash:')
      config_set('upgrade', 'delete', image: image, uri: uri)
    rescue Cisco::CliError => e
      raise e
    end

    # Deletes currently booted image
    def self.delete_boot(uri='bootflash:')
      # Incase of a N9K, N3K and N9Kv the system and kickstart images are
      # the same.
      # Incase of a N5K, N6K and N7K the system and kickstart images are
      # different.
      system_image = config_get('show_version', 'system_image').split('/')[-1]
      kickstart_image = config_get('show_version', 'boot_image').split('/')[-1]
      if kickstart_image == system_image
        config_set('upgrade', 'delete_boot', image: system_image, uri: uri)
      else
        config_set('upgrade', 'delete_boot', image: system_image,
                                             uri:   uri)
        config_set('upgrade', 'delete_boot', image: kickstart_image,
                                             uri:   uri)
      end
    rescue Cisco::CliError => e
      raise e
    end

    # Returns version of the 'image'
    def self.image_version(image=nil, uri=nil)
      # Returns version of currently booted image by default
      if image && uri
        config_get('upgrade', 'image_version', image: image, uri: uri)
      else
        config_get('show_version', 'version').split(' ')[0]
      end
    end

    # Return true if box is online and config mode is ready to be used
    def self.box_online?
      output = config_set('upgrade', 'is_box_online')
      output[0]['body'] == {}
    end

    def self.save_config
      config_set('upgrade', 'save_config')
    rescue Cisco::CliError => e
      raise e
    end

    # Returns True if device upgraded
    def self.upgraded?
      return false unless config_get('upgrade', 'upgraded')
      (0..500).each do
        sleep 1
        return true if box_online?
      end
      fail 'Configuration is still blocked'
    end

    # Attempts to upgrade the device to 'image'
    def self.upgrade(version, image, uri='bootflash:', del_boot=false,
                     force_all=false)
      # Only 'bootflash:' is a supported URI. Fail otherwise.
      fail "The Uri #{uri} is not supported" unless uri == 'bootflash:'
      # IMPORTANT - Check if version of image equals the version provided.
      # This is to avoid entering a loop with the Programmability Agent
      # continuously trying to reload the device if versions don't match.
      image_ver = image_version(image, uri)
      err_str = "Version Mismatch.\n
                 The version of the image:#{image_ver}\n
                 The version provided:#{version}\n
                 Aborting upgrade."
      fail err_str unless image_ver.to_s.strip == version.to_s.strip
      delete_boot(uri) if del_boot
      force_all ? upgrade_str = 'upgrade_force' : upgrade_str = 'upgrade'
      begin
        Cisco::Logger.debug("Upgrading to version: #{image}")
        config_set('upgrade', upgrade_str, image: image, uri: uri)
      rescue Cisco::RequestFailed
        # Catch 'Backend Processing Error'. Install continues inspite of the
        # error thrown. Resend install command and expect a CliError.
        begin
          config_set('upgrade', upgrade_str, image: image, uri: uri)
        rescue Cisco::CliError => e
          raise e unless
            e.message.include?('Another install procedure may be in progress')
        end
      end
    end
  end
end
