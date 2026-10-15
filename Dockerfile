# Utilizamos la última imagen de ubuntu como imagen base
FROM ubuntu:latest

# Establecemos el timezone
ENV TZ=Europe/Madrid

# Instalamos los paquetes del sistema necesarios para Laravel
RUN apt-get update && \
    apt-get install -y \
        apache2 \
        php \
        libapache2-mod-php \
        php-cli \
        php-common \
        php-sqlite3 \
        php-mysql \
        php-pgsql \
        php-gd \
        php-zip \
        php-bcmath \
        php-mbstring \
        php-xml \
        php-curl \
        php-intl \
        unzip \
        zip \
        git \
        curl \
        && rm -rf /var/lib/apt/lists/*

	# Habilitamos mod_rewrite de Apache para las rutas de Laravel
	RUN a2enmod rewrite

# Establecemos el directorio de trabajo en el directorio web raíz
WORKDIR /var/www/html/

# Copiamos la configuración personalizada de Apache
COPY ./config/apache2.conf /etc/apache2/apache2.conf

# Desactivamos el módulo autoindex
RUN a2dismod -f autoindex

# Creamos directorios necesarios con permisos para el usuario de apache
RUN mkdir -p /var/run/apache2 /var/lock/apache2 /var/log/apache2
RUN chown -R www-data:www-data \
 /var/run/apache2 /var/lock/apache2 /var/log/apache2

# Establecemos el directorio de trabajo
WORKDIR /var/www/html
# Copiamos la aplicación Laravel al directorio de trabajo del contenedor
COPY ./app /var/www/html/

# Instalamos Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copiamos los archivos de Composer
COPY ./app/composer.json ./app/composer.lock ./

# Copiamos el resto de la aplicación Laravel
COPY ./app/ /var/www/html/

# Instalamos las dependencias de Composer
RUN composer install \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader

# Permisos de Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache && \
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Permisos Laravel
RUN chown -R www-data:www-data \
        /var/www/html/storage \
        /var/www/html/bootstrap/cache \
        /var/www/html/database && \
    chmod -R 775 \
        /var/www/html/storage \
        /var/www/html/bootstrap/cache \
        /var/www/html/database




ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

# Establecemos la raíz web de Apache en el directorio public del proyecto
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Cambiamos de root al usuario www-data
USER www-data

# Copiamos nuestra aplicación al directorio de trabajo del contenedor
COPY . /var/www/html/

# Establecemos el directorio de trabajo en el directorio web raíz
WORKDIR /var/www/html/

# Ponemos el puerto 80 del contenedor en escucha
EXPOSE 80

# Levantamos el demonio de Apache
CMD ["apachectl", "-D", "FOREGROUND"]

