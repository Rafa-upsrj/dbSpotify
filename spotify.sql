DROP DATABASE IF EXISTS spotify;
CREATE DATABASE spotify CHARACTER SET utf8mb4;
USE spotify;

CREATE TABLE usuario (
  id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(60) NOT NULL,
  password VARCHAR(30) NOT NULL,
  email VARCHAR(160) NOT NULL UNIQUE,
  fecha_nacimiento DATE NOT NULL,
  sexo ENUM('F','M', 'I') NOT NULL,
  codigo_postal INT(5),
  pais VARCHAR(60),
  tipo ENUM('free', 'premium') DEFAULT 'free'
);

CREATE TABLE playlist (
  id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  titulo VARCHAR(60) NOT NULL,
  numeroCanciones INT DEFAULT 0,
  fechaCreacion TIMESTAMP,
  tipo ENUM('eliminada', 'Activa') DEFAULT 'Activa'
);

CREATE TABLE artista (
  id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  imagen VARCHAR(250)
);

CREATE TABLE album (
  id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  año DATE NOT NULL,
  titulo VARCHAR(60) NOT NULL,
  imagen VARCHAR(250),
  id_artista INT UNSIGNED,
  FOREIGN KEY (id_artista) REFERENCES artista(id)
);

CREATE TABLE cancion (
  id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  titulo VARCHAR(60) NOT NULL,
  duracion TIME NOT NULL,
  numeroReproducciones INT DEFAULT 0,
  id_album INT UNSIGNED,
  FOREIGN KEY (id_album) REFERENCES album(id)
);


CREATE TABLE forma_de_pago (
  id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tipo ENUM('tarjeta','paypal') NOT NULL
);

CREATE TABLE free (
  id INTEGER UNSIGNED PRIMARY KEY,
  FOREIGN KEY (id) REFERENCES usuario(id)
);

CREATE TABLE premium (
  id INTEGER UNSIGNED PRIMARY KEY,
  fecha_renovacion DATE NOT NULL,
  id_formaPago INTEGER UNSIGNED,
  FOREIGN KEY (id) REFERENCES usuario(id),
  FOREIGN KEY (id_formaPago) REFERENCES forma_de_pago(id)
);

CREATE TABLE pago (
  id INTEGER UNSIGNED PRIMARY KEY,
  fecha DATE NOT NULL,
  total INTEGER UNSIGNED,
  id_usuarioPremium INTEGER UNSIGNED,
  FOREIGN KEY (id) REFERENCES premium(id)
);

CREATE TABLE tarjetaCredito (
  id INTEGER UNSIGNED PRIMARY KEY,
  numeroTarjeta INTEGER(16) UNSIGNED,
  mesCaducidad INTEGER(2) UNSIGNED,
  aoCaducidad INTEGER(4) UNSIGNED,
  codigoSeguridad INTEGER(3) UNSIGNED,
  FOREIGN KEY (id) REFERENCES forma_de_pago(id)
);

CREATE TABLE paypal (
  id INTEGER UNSIGNED PRIMARY KEY,
  username_paypal VARCHAR(100) NOT NULL UNIQUE,
  FOREIGN KEY (id) REFERENCES forma_de_pago(id)
);

CREATE TABLE playListEliminada (
  id INTEGER UNSIGNED PRIMARY KEY,
  fechaEliminacion TIMESTAMP,
  FOREIGN KEY (id) REFERENCES playlist(id)
);

CREATE TABLE playListActiva (
  id INTEGER UNSIGNED PRIMARY KEY,
  compartida ENUM ('true', 'false'),
  FOREIGN KEY (id) REFERENCES playlist(id)
);

CREATE TABLE artista_artista (
  id INTEGER UNSIGNED PRIMARY KEY,
  id_artista INTEGER UNSIGNED,
  id_artistaRelacionado INTEGER UNSIGNED,
  FOREIGN KEY (id_artista) REFERENCES artista(id),
  FOREIGN KEY (id_artistaRelacionado) REFERENCES artista(id)
);

CREATE TABLE usuario_artista (
  id INTEGER UNSIGNED PRIMARY KEY,
  id_usuario INTEGER UNSIGNED,
  id_artista INTEGER UNSIGNED,
  FOREIGN KEY (id_usuario) REFERENCES usuario(id),
  FOREIGN KEY (id_artista) REFERENCES artista(id)
);

CREATE TABLE usuario_album (
  id INTEGER UNSIGNED PRIMARY KEY,
  id_usuario INTEGER UNSIGNED,
  id_album INTEGER UNSIGNED,
  FOREIGN KEY (id_usuario) REFERENCES usuario(id),
  FOREIGN KEY (id_album) REFERENCES album(id)
);

CREATE TABLE usuario_cancion (
  id INTEGER UNSIGNED PRIMARY KEY,
  id_usuario INTEGER UNSIGNED,
  id_cancion INTEGER UNSIGNED,
  FOREIGN KEY (id_usuario) REFERENCES usuario(id),
  FOREIGN KEY (id_cancion) REFERENCES cancion(id)
);

CREATE TABLE usuario_playlist (
  id INTEGER UNSIGNED PRIMARY KEY,
  creador INTEGER UNSIGNED,
  id_usuario INTEGER UNSIGNED,
  id_cancion INTEGER UNSIGNED,
  FOREIGN KEY (creador) REFERENCES usuario(id),
  FOREIGN KEY (id_usuario) REFERENCES usuario(id),
  FOREIGN KEY (id_cancion) REFERENCES cancion(id)
);

CREATE TABLE usuario_playlist_cancion (
  id INTEGER UNSIGNED PRIMARY KEY,
  fecha DATE NOT NULL,
  id_usuario INTEGER UNSIGNED,
  id_playlist INTEGER UNSIGNED,
  id_cancion INTEGER UNSIGNED,
  FOREIGN KEY (id_usuario) REFERENCES usuario(id),
  FOREIGN KEY (id_playlist) REFERENCES playlist(id),
  FOREIGN KEY (id_cancion) REFERENCES cancion(id)
);

DELIMITER $
CREATE TRIGGER comprobar_artista_repetido_BI BEFORE INSERT ON artista_artista
    FOR EACH ROW
    BEGIN
        IF (NEW.id_artista = NEW.id_artistaRelacionado ) THEN 
            BEGIN
                SIGNAL SQLSTATE '40000' SET MESSAGE_TEXT = 'No se puede relacionar un artista con el mismo';
            END;
        END IF;
    END;$
DELIMITER ;

DELIMITER $
CREATE TRIGGER comprobar_tajetaCredito_formaPago_BI BEFORE INSERT ON tarjetaCredito
    FOR EACH ROW
    BEGIN
        IF ((SELECT tipo FROM forma_de_pago WHERE id = NEW.id) != 'tarjeta') THEN 
            BEGIN
                SIGNAL SQLSTATE '40000' SET MESSAGE_TEXT = 'No se registrar tajeta con forma de pago de tipo paypal';
            END;
        ELSE IF((SELECT YEAR(NOW())) <= NEW.aoCaducidad) THEN
            BEGIN
                IF ((SELECT MONTH(NOW())) > NEW.mesCaducidad) THEN
                    BEGIN
                        SIGNAL SQLSTATE '40000' SET MESSAGE_TEXT = 'EL mes de la tarjeta ya caduco';
                    END;
                END IF;
            END;
        ELSE SIGNAL SQLSTATE '40000' SET MESSAGE_TEXT = 'el ao de la tarjeta ya caduco';
        END IF;
        END IF;
    END;$
DELIMITER ;


INSERT INTO forma_de_pago(tipo) VALUES('tarjeta'),('paypal');
INSERT INTO tarjetaCredito(id,numeroTarjeta,mesCaducidad,aoCaducidad,codigoSeguridad) 
VALUES(3,12,07,2020,123);