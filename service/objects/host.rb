require 'rbvmomi'

class OpenNebula::Host
  VIM = RbVmomi::VIM # Alias for RbVmomi::VIM

  def vim
    host = to_hash!['HOST']['TEMPLATE']

    VIM.connect(
      :host => host['VCENTER_HOST'], :insecure => true,
      :user => host['VCENTER_USER'], :password => host['VCENTER_PASSWORD_ACTUAL']
    )
  end
end
