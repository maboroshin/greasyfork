require 'json'
require 'uri'
require 'net/http'

namespace :licenses do
  desc 'update license list'
  task update_list: :environment do
    uri = URI.parse('https://raw.githubusercontent.com/spdx/license-list-data/master/json/licenses.json')
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new uri
      response = http.request(request)
      raise "HTTP response #{response_code}." if response.code != '200'

      result = JSON.parse(response.body)
      result['licenses'].each do |license_data|
        license = License.find_or_initialize_by(code: license_data['licenseId'])
        license.name = license_data['name']
        license.url = license_data['reference']
        license.save!
      end
    end
  end

  desc 'update script licenses'
  task update_scripts: :environment do
    Script.find_each do |script|
      sv = script.script_versions.last
      script.update_license(sv.meta['license']&.first&.first(500))
      script.save(validate: false) if script.changed?
    end
  end
end
