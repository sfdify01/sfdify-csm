from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError
from django.contrib.auth import authenticate, get_user_model

from .serializers import (
    CustomTokenObtainPairSerializer,
    LoginSerializer,
    UserSerializer,
    LogoutSerializer,
)

User = get_user_model()


class LoginView(TokenObtainPairView):
    """
    JWT Login endpoint.

    POST /api/v1/auth/login/
    {
        "email": "user@example.com",  // or "username": "user"
        "password": "password",
        "totp_code": "123456"  // Optional, for 2FA
    }

    Returns:
    {
        "access": "eyJ...",
        "refresh": "eyJ...",
        "user": {...}
    }
    """
    permission_classes = [AllowAny]
    serializer_class = CustomTokenObtainPairSerializer

    def post(self, request, *args, **kwargs):
        # Support email-based login
        data = request.data.copy()

        # If email provided, find username
        if 'email' in data and 'username' not in data:
            email = data.get('email')
            try:
                user = User.objects.get(email=email)
                data['username'] = user.username
            except User.DoesNotExist:
                return Response(
                    {
                        'error': 'invalid_credentials',
                        'message': 'Invalid email or password'
                    },
                    status=status.HTTP_401_UNAUTHORIZED
                )

        # Update request data
        request._full_data = data

        try:
            response = super().post(request, *args, **kwargs)

            # Rename tokens for API consistency
            if response.status_code == 200:
                response.data['access_token'] = response.data.pop('access', None)
                response.data['refresh_token'] = response.data.pop('refresh', None)
                response.data['token_type'] = 'Bearer'
                response.data['expires_in'] = 900  # 15 minutes

            return response

        except Exception as e:
            return Response(
                {
                    'error': 'invalid_credentials',
                    'message': 'Invalid credentials'
                },
                status=status.HTTP_401_UNAUTHORIZED
            )


class TokenRefreshAPIView(TokenRefreshView):
    """
    Token refresh endpoint.

    POST /api/v1/auth/refresh/
    {
        "refresh_token": "eyJ..."
    }

    Returns:
    {
        "access_token": "eyJ...",
        "expires_in": 900
    }
    """
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        # Support refresh_token field name
        data = request.data.copy()
        if 'refresh_token' in data and 'refresh' not in data:
            data['refresh'] = data['refresh_token']
        request._full_data = data

        try:
            response = super().post(request, *args, **kwargs)

            if response.status_code == 200:
                response.data['access_token'] = response.data.pop('access', None)
                response.data['expires_in'] = 900

            return response

        except TokenError as e:
            return Response(
                {
                    'error': 'invalid_token',
                    'message': str(e)
                },
                status=status.HTTP_401_UNAUTHORIZED
            )


class LogoutView(APIView):
    """
    Logout endpoint - blacklists the refresh token.

    POST /api/v1/auth/logout/
    {
        "refresh_token": "eyJ..."
    }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = LogoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            token = RefreshToken(serializer.validated_data['refresh_token'])
            token.blacklist()
            return Response(
                {'message': 'Successfully logged out'},
                status=status.HTTP_200_OK
            )
        except TokenError as e:
            return Response(
                {
                    'error': 'invalid_token',
                    'message': str(e)
                },
                status=status.HTTP_400_BAD_REQUEST
            )


class MeView(APIView):
    """
    Get current user info.

    GET /api/v1/auth/me/

    Returns user profile with role and permissions.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        data = serializer.data

        # Add tenant info if available
        if hasattr(request, 'tenant') and request.tenant:
            data['tenant'] = {
                'id': str(request.tenant.id),
                'name': request.tenant.name,
                'plan': request.tenant.plan,
            }

        return Response(data)


class ChangePasswordView(APIView):
    """
    Change password endpoint.

    POST /api/v1/auth/change-password/
    {
        "old_password": "...",
        "new_password": "..."
    }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        old_password = request.data.get('old_password')
        new_password = request.data.get('new_password')

        if not old_password or not new_password:
            return Response(
                {
                    'error': 'validation_error',
                    'message': 'Both old_password and new_password are required'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if not request.user.check_password(old_password):
            return Response(
                {
                    'error': 'invalid_password',
                    'message': 'Current password is incorrect'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if len(new_password) < 8:
            return Response(
                {
                    'error': 'validation_error',
                    'message': 'Password must be at least 8 characters'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        request.user.set_password(new_password)
        request.user.save()

        return Response({'message': 'Password changed successfully'})
