require 'rbvmomi'

class OpenNebula::Host
  VIM = RbVmomi::VIM # Alias for RbVmomi::VIM

  def vim
    info! true
    VIM.connect(
      :host => self['//VCENTER_HOST'], :insecure => true,
      :user => self['//VCENTER_USER'], :password => self['//VCENTER_PASSWORD']
    )
  end
end
