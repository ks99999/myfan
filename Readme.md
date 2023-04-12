##Вступление.
Этот проект является логическим продолжением серии авторских авторегулировщиков PWM кулеров для ригов.
И создан по мотивам таких автофанов как coolboxfan, donnager autofan и др.
Цель проекта - минимальными средствами (в т.ч. потраченным временем) получить работающий автофан.
Если Вам нужны: вочдог, контроль оборотов и прочее, то купите готовое устройство вышеупомянутых производителей.
Реализовано управление прямо из интерфейса HiveOS. Есть так же цифровой температурный датчик окружающего воздуха 0-40 градусов.
Проект состоит из двух частей: программной и аппаратной.
Аппаратная часть - любая ардуино-совместимая платформа с USB интерфесом.
Программная часть - набор скриптов для взаимодействия с HiveOS.

##Аппаратная часть.
Залить программу myfan3.ino.hex в ардуину:
avrdude -p m328p -c arduino -P /dev/ttyACM0 -b 57600 -U flash:w:myfan3.ino.hex:i
предварительно подставить свои параметры порта.
Подключить датчик DHT11 по стандартной схеме (10К резистор между 1 и 2 ногой) к D2 выводу.
Можно без датчика DHT11, тогда не будет температуры в HiveOS.
Подтянуть вывод D3 к земле резистором 10К, чтобы вентиляторы не крутились на 100% при запуске платы.
ШИМ модуляция будет на выходе D3 его надо соединить со входом PWM кулера.
Схема соединений приведена ниже
![myfan](https://github.com/ks99999/myfan/blob/0095ab056df4dfadf17318cc23f42f077498bd6c/myfan%20circuit.png)
Если кулеров несколько, то необходим еще фанхаб.
Если кулер запитывается от отдельного блока питания, то необходимо соединить минусы всех источников тока!
Работа проверялась на клоне ардуино с чипом CH340 и совместимой платой LGT8F328P (Для этой платы отдельная прошивка myfan3-LGT8F328P.ino.hex)

##Программная часть.
выполнить на риге команду:
curl https://raw.githubusercontent.com/ks99999/myfan/main/myfan-setup.sh | bash
которая скачает и установит все необходимые скрипты.
Установщик выведет сообщение об успешной или неуспешной установке.
После установки, если подключена плата, в HiveOS появится снежинка с возможностью управлять внешними кулером.
При обновлении HiveOS возможна перезапись файлов myfan, тогда надо повторить установку программной части.

##Ограничения myfan:
не поддерживает калибровку
не поддерживает раздельное регулирование кулерами
В скетче зашито стартовое значение PWM=2% для некоторых кулеров это может быть мало для начала вращения.
Как вариант можно в настройках HiveOS выставить минимальное значение PWM которое устроит.

Проект постоянно дорабатывается.
В ближайших планах доработать: версии прошивок, корректное определение в риге наличие автофана, удаленное обновление прошивки контроллера.

У автора myfan подключен к Fan hub одним пином PWM. Этого достаточно для управления до 10 кулеров.

Для предложений и багов просьба писать автору на a@korshunov.me,  telegram @Alexandr_admin
