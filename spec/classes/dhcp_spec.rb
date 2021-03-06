require 'spec_helper'
require 'puppetlabs_spec_helper/module_spec_helper'
describe 'dhcp', :type => :class do
  let :default_params do
    {
      'dnsdomain'   => ['sampledomain.com','1.1.1.in-addr.arpa'],
      'nameservers' => ['1.1.1.1'],
      'ntpservers'  => ['time.sample.com'],
    }
  end
  context 'on a RedHat OS' do
    let :facts do
      {
        :osfamily               => 'RedHat',
        :operatingsystem        => 'RedHat',
        :operatingsystemrelease => '6',
        :concat_basedir         => '/dne',
      }
    end
    context 'called with defaults and mandatory params' do
      let :params do
        default_params
      end
      it 'should fail to compile' do
        expect { should compile }.to raise_error()
      end
      context 'input validation' do
        ['dnsdomain','nameservers','ntpservers'].each do |arrays|
          context "when #{arrays} is not an array" do
            it 'should fail' do
              params.merge!({ arrays => 'BOGON'})
              expect { subject }.to raise_error(Puppet::Error, /"BOGON" is not an Array.  It looks to be a String/)
            end
          end
        end
      end
    end
    context 'coverage tests' do
      let :params do
        default_params.merge({
          :interface => 'eth0',
        })
       end
      ['dhcp','dhcp::monitor'].each do |dhclasses|
        it {should contain_class(dhclasses)}
      end
      ['/etc/dhcp/dhcpd.pools','/etc/dhcp/dhcpd.hosts'].each do |concats|
        it {should contain_concat(concats)}
      end
      ['dhcp-conf-pxe','dhcp-conf-extra'].each do |frags|
        it {should contain_concat__fragment(frags)}
      end
      ['/etc/dhcp/dhcpd.conf','/etc/dhcp/dhcpd.pools'].each do |files|
        it {should contain_file(files)}
      end
    end
  end
  context 'on a Dawin OS' do
    let :facts do
      {
        :osfamily               => 'Darwin',
        :concat_basedir         => '/dne',
      }
    end
    let :params do
      default_params.merge({
        :interface => 'eth0',
      })
    end
    it { should compile }
    it { should contain_package('dhcp') \
      .with_provider('macports')
    }
  end
  context 'on a Debian based OS' do
    let :default_facts do
      {
        :osfamily       => 'Debian',
        :concat_basedir => '/dne',
      }
    end
    context 'Debian' do
      let :facts do
        default_facts.merge({
          :operatingsystem => 'Debian',
        })
      end
      let :params do
        default_params.merge({
          :interface => 'eth0',
        })
      end
      it { should contain_package('isc-dhcp-server') }
      it { should contain_file('/etc/default/isc-dhcp-server') \
        .with_content(/INTERFACES=\"eth0\"/)
      }
    end
    context 'Ubuntu' do
      let :params do
        default_params.merge({
          :interface => 'eth0',
        })
      end
      context '12.04' do
        let :facts do
          default_facts.merge({
            :operatingsystem        => 'Ubuntu',
            :operatingsystemrelease => '12.04',
          })
        end
        it { should contain_file('/etc/dhcp/dhcpd.conf') }
      end
      context '10.04' do
        let :facts do
          default_facts.merge({
            :operatingsystem        => 'Ubuntu',
            :operatingsystemrelease => '10.04',
          })
        end
        it { should contain_file('/etc/dhcp3/dhcpd.conf') }
      end
    end
  end
end
