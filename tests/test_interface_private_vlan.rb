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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/interface'
require_relative '../lib/cisco_node_utils/vlan'

include Cisco

# TestInterfacePrivateVlan
# Parent class for specific types of switchport tests (below)
class TestInterfacePrivateVlan < CiscoTestCase
  # rubocop:disable Style/ClassVars
  @@pre_clean_needed = true
  attr_reader :i

  def i
    @@interface
  end

  def setup
    super
    return unless @@pre_clean_needed
    cleanup
    @@interface = Interface.new(interfaces[0])
    @@pre_clean_needed = false
  end
  # rubocop:enable Style/ClassVars

  def teardown
    cleanup
    super
  end

  def cleanup
    interface_cleanup_pvlan
    remove_all_vlans
    config_no_warn('no feature private-vlan', 'no feature vtp')
  end

  def interface_cleanup_pvlan
    pvlan_intfs = Interface.interfaces(:pvlan_any)
    pvlan_intfs.keys.each { |name| interface_cleanup(name) }
  end

  def test_switchport_pvlan_host
    if validate_property_excluded?('interface',
                                   'switchport_pvlan_host')
      assert_raises(Cisco::UnsupportedError) do
        i.switchport_pvlan_host = true
      end
      return
    end

    assert_equal(i.default_switchport_pvlan_host,
                 i.switchport_pvlan_host)

    i.switchport_pvlan_host = true
    assert(i.switchport_pvlan_host)

    i.switchport_pvlan_host = false
    refute(i.switchport_pvlan_host)
  end

  def test_switchport_pvlan_promiscuous
    if validate_property_excluded?('interface',
                                   'switchport_pvlan_promiscuous')
      assert_raises(Cisco::UnsupportedError) do
        i.switchport_pvlan_promiscuous = true
      end
      return
    end

    assert_equal(i.default_switchport_pvlan_promiscuous,
                 i.switchport_pvlan_promiscuous)

    i.switchport_pvlan_promiscuous = true
    assert(i.switchport_pvlan_promiscuous)

    i.switchport_pvlan_promiscuous = false
    refute(i.switchport_pvlan_promiscuous)
  end

  def test_switchport_pvlan_trunk_promiscuous
    if validate_property_excluded?('interface',
                                   'switchport_pvlan_trunk_promiscuous')
      assert_raises(Cisco::UnsupportedError) do
        i.switchport_pvlan_trunk_promiscuous = true
      end
      return
    end

    assert_equal(i.default_switchport_pvlan_trunk_promiscuous,
                 i.switchport_pvlan_trunk_promiscuous)

    i.switchport_pvlan_trunk_promiscuous = true
    assert(i.switchport_pvlan_trunk_promiscuous)

    i.switchport_pvlan_trunk_promiscuous = false
    refute(i.switchport_pvlan_trunk_promiscuous)
  end

  def test_switchport_pvlan_trunk_secondary
    if validate_property_excluded?('interface',
                                   'switchport_pvlan_trunk_secondary')
      assert_raises(Cisco::UnsupportedError) do
        i.switchport_pvlan_trunk_secondary = true
      end
      return
    end

    assert_equal(i.default_switchport_pvlan_trunk_secondary,
                 i.switchport_pvlan_trunk_secondary)

    i.switchport_pvlan_trunk_secondary = true
    assert(i.switchport_pvlan_trunk_secondary)

    i.switchport_pvlan_trunk_secondary = false
    refute(i.switchport_pvlan_trunk_secondary)
  end

  # Helper to setup vlan association prerequisites
  def vlan_associate(pri, sec)
    Vlan.new(sec).private_vlan_type = 'community'
    Vlan.new(pri).private_vlan_type = 'primary'
    Vlan.new(pri).private_vlan_association = sec
  end

  def test_switchport_pvlan_host_association
    # Supports single instance of [pri, sec]
    if validate_property_excluded?('interface',
                                   'switchport_pvlan_host_association')
      assert_raises(Cisco::UnsupportedError) do
        i.switchport_pvlan_host_association = %w(2 3)
      end
      return
    end

    default = i.default_switchport_pvlan_host_association
    assert_equal(default, i.switchport_pvlan_host_association)

    # Setup prerequisites
    vlan_associate('2', '3')

    i.switchport_pvlan_host_association = %w(2 3)
    assert_equal(%w(2 3), i.switchport_pvlan_host_association)

    i.switchport_pvlan_host_association = default
    assert_equal(default, i.switchport_pvlan_host_association)
  end

  def test_switchport_pvlan_trunk_association
    # Supports multiple instances of [[pri, sec], [pri2, sec2]]
    if validate_property_excluded?('interface',
                                   'switchport_pvlan_trunk_association')
      assert_raises(Cisco::UnsupportedError) do
        i.switchport_pvlan_trunk_association = %w(2 3)
      end
      return
    end

    default = i.default_switchport_pvlan_trunk_association
    assert_equal(default, i.switchport_pvlan_trunk_association)

    pairs = %w(2 3)
    i.switchport_pvlan_trunk_association = pairs
    assert_equal([pairs], i.switchport_pvlan_trunk_association)

    # Add a second pairs
    pairs = [%w(2 3), %w(4 5)]
    i.switchport_pvlan_trunk_association = pairs
    assert_equal(pairs, i.switchport_pvlan_trunk_association)

    # New pair
    pairs = [%w(6 7)]
    i.switchport_pvlan_trunk_association = pairs
    assert_equal(pairs, i.switchport_pvlan_trunk_association)

    i.switchport_pvlan_trunk_association = default
    assert_equal(default, i.switchport_pvlan_trunk_association)
  end

  def test_pvlan_mapping
    # This is an SVI property
    svi = Interface.new('vlan13')
    if validate_property_excluded?('interface', 'pvlan_mapping')
      assert_raises(Cisco::UnsupportedError) do
        svi.pvlan_mapping = ['10-11,4-7,8']
      end
      return
    end

    default = svi.default_pvlan_mapping
    assert_equal(default, svi.pvlan_mapping)

    # Input can be Array or String
    svi.pvlan_mapping = ['10-11,4-7,8']
    assert_equal('4-8,10-11', svi.pvlan_mapping)

    # Change range
    svi.pvlan_mapping = '11,4-6,8'
    assert_equal('4-6,8,11', svi.pvlan_mapping)

    svi.pvlan_mapping = default
    assert_equal(default, svi.pvlan_mapping)
  end

  def test_switchport_pvlan_mapping
    if validate_property_excluded?('interface', 'switchport_pvlan_mapping')
      assert_raises(Cisco::UnsupportedError) do
        i.switchport_pvlan_mapping = ['2', '10-11,4-7,8']
      end
      return
    end

    default = i.default_switchport_pvlan_mapping
    assert_equal(default, i.switchport_pvlan_mapping)

    # Setup prerequisites
    vlan_associate('2', '3')

    i.switchport_pvlan_mapping = %w(2 3)
    assert_equal(%w(2 3), i.switchport_pvlan_mapping)

    i.switchport_pvlan_mapping = default
    assert_equal(default, i.switchport_pvlan_mapping)
  end

  def test_switchport_pvlan_mapping_trunk
    if validate_property_excluded?('interface',
                                   'switchport_pvlan_mapping_trunk')
      assert_raises(Cisco::UnsupportedError) do
        i.switchport_pvlan_mapping_trunk = ['2', '10-11,4-7,8']
      end
      return
    end

    default = i.default_switchport_pvlan_mapping_trunk
    assert_equal(default, i.switchport_pvlan_mapping_trunk)

    i.switchport_pvlan_mapping_trunk = ['2', '10-11,4-7,8']
    assert_equal(['2', '4-8,10-11'], i.switchport_pvlan_mapping_trunk)

    # Same primary, but change range
    i.switchport_pvlan_mapping_trunk = ['2', '11,4-6,8']
    assert_equal(['2', '4-6,8,11'], i.switchport_pvlan_mapping_trunk)

    # Change primary
    i.switchport_pvlan_mapping_trunk = ['3', '11,4-6,8']
    assert_equal(['3', '4-6,8,11'], i.switchport_pvlan_mapping_trunk)

    i.switchport_pvlan_mapping_trunk = default
    assert_equal(default, i.switchport_pvlan_mapping_trunk)
  end

  def test_switchport_pvlan_trunk_allowed_vlan
    if validate_property_excluded?('interface',
                                   'switchport_pvlan_trunk_allowed_vlan')
      assert_raises(Cisco::UnsupportedError) do
        i.switchport_pvlan_trunk_allowed_vlan = '8-9,4,2-3'
      end
      return
    end

    default = i.default_switchport_pvlan_trunk_allowed_vlan
    assert_equal(default, i.switchport_pvlan_trunk_allowed_vlan)

    i.switchport_pvlan_trunk_allowed_vlan = '8-9,4,2-3'
    assert_equal('2-4,8-9', i.switchport_pvlan_trunk_allowed_vlan)

    # Change range
    i.switchport_pvlan_trunk_allowed_vlan = '9-10,2'
    assert_equal('2,9-10', i.switchport_pvlan_trunk_allowed_vlan)

    i.switchport_pvlan_trunk_allowed_vlan = default
    assert_equal(default, i.switchport_pvlan_trunk_allowed_vlan)
  end

  def test_switchport_pvlan_trunk_native_vlan
    if validate_property_excluded?('interface',
                                   'switchport_pvlan_trunk_native_vlan')
      assert_raises(Cisco::UnsupportedError) do
        i.switchport_pvlan_trunk_native_vlan = '2'
      end
      return
    end

    default = i.default_switchport_pvlan_trunk_native_vlan
    assert_equal(default, i.switchport_pvlan_trunk_native_vlan)

    i.switchport_pvlan_trunk_native_vlan = '2'
    assert_equal('2', i.switchport_pvlan_trunk_native_vlan)

    i.switchport_pvlan_trunk_native_vlan = default
    assert_equal(default, i.switchport_pvlan_trunk_native_vlan)
  end
end
