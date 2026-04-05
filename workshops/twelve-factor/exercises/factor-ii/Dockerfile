# Factor II — Dependencies: explicitly declared, isolated
# Before: AppCo's legacy app assumed 'soap' was installed on the host.
# After:  Every dependency is declared here. No surprises across environments.

FROM php:8.2-fpm

# System-level dependencies declared explicitly — no implicit host assumptions
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libpq-dev \
    && docker-php-ext-install soap pdo pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*

# Composer for PHP package management (pinned version = reproducible builds)
COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Declare application-level dependencies before copying source
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader

COPY . .
RUN composer dump-autoload --optimize

EXPOSE 9000
CMD ["php-fpm"]
