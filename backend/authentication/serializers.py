from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model

User = get_user_model()


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Custom JWT token serializer that includes tenant_id and role in claims."""

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)

        # Add custom claims
        token['email'] = user.email
        token['username'] = user.username

        # Add role if user has agent profile
        if hasattr(user, 'agentprofile'):
            token['role'] = user.agentprofile.role
        else:
            token['role'] = 'user'

        return token

    def validate(self, attrs):
        data = super().validate(attrs)

        # Add user info to response
        data['user'] = {
            'id': self.user.id,
            'email': self.user.email,
            'username': self.user.username,
            'first_name': self.user.first_name,
            'last_name': self.user.last_name,
        }

        # Add role
        if hasattr(self.user, 'agentprofile'):
            data['user']['role'] = self.user.agentprofile.role
        else:
            data['user']['role'] = 'user'

        return data


class LoginSerializer(serializers.Serializer):
    """Serializer for login request."""
    email = serializers.EmailField(required=False)
    username = serializers.CharField(required=False)
    password = serializers.CharField(write_only=True)
    totp_code = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        if not attrs.get('email') and not attrs.get('username'):
            raise serializers.ValidationError(
                "Either email or username is required."
            )
        return attrs


class UserSerializer(serializers.ModelSerializer):
    """Serializer for user details."""
    role = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'email', 'username', 'first_name', 'last_name', 'role', 'is_active', 'date_joined']
        read_only_fields = fields

    def get_role(self, obj):
        if hasattr(obj, 'agentprofile'):
            return obj.agentprofile.role
        return 'user'


class TokenRefreshResponseSerializer(serializers.Serializer):
    """Response serializer for token refresh."""
    access = serializers.CharField()
    access_token = serializers.CharField()


class LogoutSerializer(serializers.Serializer):
    """Serializer for logout request."""
    refresh_token = serializers.CharField()
