# Copyright (C) 2018 Dell EMC, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vcenter')
require 'rbvmomi'

Puppet::Type.type(:esx_pci_passthru_system).provide(:esx_pci_passthru_system, :parent => Puppet::Provider::Vcenter) do
  @doc = "Manages Passthrough System."

  def create
    Puppet.debug "Entered in create pci passthru config method."
    begin
      pci_device_ids = resource[:pci_device_id]
      Puppet.debug("pci_device_ids: %s" % pci_device_ids)
      for pci_device_id in pci_device_ids
        pci_device_config = RbVmomi::VIM.HostPciPassthruConfig(:id => pci_device_id, :passthruEnabled => true)
        pci_passthu_system.UpdatePassthruConfig(:config => [pci_device_config])
        # sleep for 30 seconds to make sure that the configuration change is written
        sleep 30
      end
      if !active? && resource[:require_reboot]
        Puppet.debug "Reboot the host to activate the PCI passthrough"
        reboot
      elsif (enabled? && active?)
        Puppet.debug "Target device is already enabled and activated."
      elsif (enabled? && !resource[:require_reboot])
        Puppet.debug "It is enabled, but activation requires a reboot later."
      end
    rescue
      fail "Failed to enable PCI passthrough with following error, %s:%s" % [$!.class, $!.message]
    end
  end

  def destroy
    Puppet.debug "Entered in destroy pci passthru config method."
    begin
      pci_device_ids = resource[:pci_device_id]
      Puppet.debug("pci_device_ids: %s" % pci_device_ids)
      for pci_device_id in pci_device_ids
        pci_device_config = RbVmomi::VIM.HostPciPassthruConfig(:id => pci_device_id, :passthruEnabled => false)
        pci_passthu_system.UpdatePassthruConfig(:config => [pci_device_config])
        # sleep for 30 seconds to make sure that the configuration change is written
        sleep 30
      end

      if active? && resource[:require_reboot]
        Puppet.debug "Reboot the host to deactivate the PCI passthrough"
        reboot
      elsif (!enabled? && !active?)
        Puppet.debug "Target device is disabled and deactivated."
      elsif(!enabled && !resource[:require_reboot])
        Puppet.debug "Target device is disabled. Its deactivation requires a reboot."
      end
    rescue
      fail "Failed to disable PCI passthrough with following error, %s:%s" % [$!.class, $!.message]
    end
  end

  def exists?
    enabled? && (active? || !resource[:require_reboot])
  end

  def enabled?
    Puppet.debug "Check if the PCI passthrough setting is enabled on the target device"
    pci_device_ids = resource[:pci_device_id]
    for pci_device_id in pci_device_ids
      device = pci_passthu_system.pciPassthruInfo.find { |pci| pci.id == pci_device_id }
      return false if device.nil? || device.passthruEnabled == false
    end
    true
  end

  def active?
    Puppet.debug "Check if the PCI passthrough setting is active on the target device"
    pci_device_ids = resource[:pci_device_id]
    for pci_device_id in pci_device_ids
      device = pci_passthu_system.pciPassthruInfo.find { |pci| pci.id == pci_device_id }
      return false if device.nil? || device.passthruActive == false
    end
    true
  end

  ####################################################################################################################
  ########################################## HELPER METHODS ##########################################################
  ####################################################################################################################
  def pci_passthu_system
    Puppet.debug "Getting PCI Passthrough system from esxhost, #{host.name}"
    @pci_passthru_sys ||= host.configManager.pciPassthruSystem
  end

  def reboot
    host.RebootHost_Task({:force => false}).wait_for_completion
    wait_for_host(300, resource[:reboot_timeout])
  end
end
