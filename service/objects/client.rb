# Extensions for OpenNebula::Client
class OpenNebula::Client
    # Returns user id for given credentials
    def user_id
        u = user!
        u.id
    end
    # Returns user for given credentials
    def user
        OpenNebula::User.new_with_id(-1, self)
    end
    # Returns user for given credentials with info! executed
    def user!
        u = user
        u.info!
        u
    end
end