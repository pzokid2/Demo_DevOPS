# compliance/exposure/controls/app_exposure.rb – Compliance-as-Code cho gate G4
# Chạy: cinc-auditor exec compliance/exposure --input app_url=http://127.0.0.1:8080

app = input('app_url')

control 'pol-03-sensitive-paths' do
  impact 0.8
  title 'Reverse proxy không để lộ thư mục nội bộ của Juice Shop'
  desc  'POL-03, POL-11; GDPR Art.5(1)(f), Art.32; Luật 91/2025. ' \
        '/ftp chứa tài liệu mật và PDF đơn hàng (email khách), /support/logs chứa IP, ' \
        '/encryptionkeys chứa khóa JWT, /metrics là số liệu nội bộ.'
  tag   policy: 'POL-03', gate: 'G4'

  # /FTP kiểm tra việc chặn không phân biệt hoa thường
  %w[/ftp /FTP /ftp/acquisitions.md /support/logs /encryptionkeys /metrics].each do |path|
    describe http("#{app}#{path}") do
      its('status') { should be_in [403, 404] }
    end
  end
end

control 'app-still-reachable' do
  impact 0.5
  title 'Ứng dụng vẫn truy cập được qua Nginx sau khi chặn'
  describe http("#{app}/") do
    its('status') { should cmp 200 }
  end
end
