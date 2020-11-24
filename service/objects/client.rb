class OpenNebula::Client
    def user_id
        u = user!
        u.id
    end
    def user
        OpenNebula::User.new_with_id(-1, self)
    end
    def user!
        u = user
        u.info!
        u
    end
end