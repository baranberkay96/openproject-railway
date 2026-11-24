# Set the password of OpenProject's seeded administrator from RAILWAY_ADMIN_PASSWORD.
# Run by railway-start (as the app user, with `rails runner`) only when the instance was
# locked on its first boot or when ADMIN_PASSWORD_RESET=true. Never prints the password.
password = ENV.fetch("RAILWAY_ADMIN_PASSWORD", "")
user = User.not_builtin.admin.find_by(login: "admin") || User.not_builtin.admin.order(:id).first
if user.nil?
  puts "[railway-admin] WARNING: no administrator found; nothing changed."
  exit 0
end
user.password = password
user.password_confirmation = password
user.force_password_change = false
user.status = User.statuses[:active]
user.failed_login_count = 0 if user.respond_to?(:failed_login_count=)
if user.save
  puts "[railway-admin] password of administrator '#{user.login}' set from ADMIN_PASSWORD."
  exit 0
else
  puts "[railway-admin] WARNING: password not changed: #{user.errors.full_messages.join('; ')}"
  exit 1
end
