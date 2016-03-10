# February 2016, Sai Chintalapudi
#
# Copyright (c) 2016 Cisco and/or its affiliates.
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

module Cisco
  # node_utils class for itd_device_group
  class ItdDeviceGroup < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name.length > 0
      @name = name

      set_args_keys_default
      create if instantiate
    end

    def self.itds
      hash = {}
      groups = config_get('itd_device_group',
                          'all_itd_device_groups')
      return hash if groups.nil?

      groups.each do |id|
        hash[id] = ItdDeviceGroup.new(id, false)
      end
      hash
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def create
      Feature.itd_enable
      config_set('itd_device_group', 'create', name: @name)
    end

    def destroy
      config_set('itd_device_group', 'destroy', name: @name)
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @set_args = { name: @name }
      @get_args = @set_args
    end

    # probe configuration is all done in a single line (like below)
    # probe tcp port 32 frequency 10 timeout 5 retry-down-count 3 ...
    # probe udp port 23 frequency 10 timeout 5 retry-down-count 3 ...
    # probe icmp frequency 10 timeout 5 retry-down-count 3 retry-up-count 3
    # probe dns host 8.8.8.8 frequency 10 timeout 5 retry-down-count 3 ...
    # also the 'control enable' can be set if the type is tcp or udp only
    # probe udp port 23 control enable frequency 10 timeout 5 ...
    def probe_get
      params = config_get('itd_device_group', 'probe', @get_args)
      hash = {}
      hash[:probe_control] = default_probe_control
      if params.nil?
        hash[:probe_frequency] = default_probe_frequency
        hash[:probe_timeout] = default_probe_timeout
        hash[:probe_retry_down] = default_probe_retry_down
        hash[:probe_retry_up] = default_probe_retry_up
        hash[:probe_type] = default_probe_type
        return hash
      end
      hash[:probe_frequency] = params[1].to_i
      hash[:probe_timeout] = params[2].to_i
      hash[:probe_retry_down] = params[3].to_i
      hash[:probe_retry_up] = params[4].to_i

      lparams = params[0].split
      hash[:probe_type] = lparams[0]
      case hash[:probe_type].to_sym
      when :dns
        hash[:probe_dns_host] = lparams[2]
      when :tcp, :udp
        hash[:probe_port] = lparams[2].to_i
        hash[:probe_control] = true unless lparams[3].nil?
      end
      hash
    end

    def probe_control
      probe_get[:probe_control]
    end

    def default_probe_control
      config_get_default('itd_device_group', 'probe_control')
    end

    def probe_dns_host
      probe_get[:probe_dns_host]
    end

    def probe_frequency
      probe_get[:probe_frequency]
    end

    def default_probe_frequency
      config_get_default('itd_device_group', 'probe_frequency')
    end

    def probe_port
      probe_get[:probe_port]
    end

    def probe_retry_down
      probe_get[:probe_retry_down]
    end

    def default_probe_retry_down
      config_get_default('itd_device_group', 'probe_retry_down')
    end

    def probe_retry_up
      probe_get[:probe_retry_up]
    end

    def default_probe_retry_up
      config_get_default('itd_device_group', 'probe_retry_up')
    end

    def probe_timeout
      probe_get[:probe_timeout]
    end

    def default_probe_timeout
      config_get_default('itd_device_group', 'probe_timeout')
    end

    def probe_type
      probe_get[:probe_type]
    end

    def default_probe_type
      config_get_default('itd_device_group', 'probe_type')
    end

    def probe=(type, host, control, freq, ret_up, ret_down, port, timeout)
      if type == false
        @set_args[:state] = 'no'
        config_set('itd_device_group', 'probe_type', @set_args)
        set_args_keys_default
        return
      end
      @set_args[:type] = type
      @set_args[:freq] = freq
      @set_args[:to] = timeout
      @set_args[:rdc] = ret_down
      @set_args[:ruc] = ret_up
      case type.to_sym
      when :dns
        @set_args[:hps] = 'host'
        @set_args[:hpv] = host
        @set_args[:control] = ''
        config_set('itd_device_group', 'probe', @set_args)
      when :tcp, :udp
        control_str = control ? 'control enable' : ''
        @set_args[:hps] = 'port'
        @set_args[:hpv] = port
        @set_args[:control] = control_str
        config_set('itd_device_group', 'probe', @set_args)
      when :icmp
        @set_args[:hps] = ''
        @set_args[:hpv] = ''
        @set_args[:control] = ''
        config_set('itd_device_group', 'probe', @set_args)
      end
      set_args_keys_default
    end
  end  # Class
end    # Module
