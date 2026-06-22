# Курсовая работа на профессии "DevOps-инженер с нуля" - Старцев Данила Антонович

## Содержание

1. [Задача](#задача)
2. [Инфраструктура](#инфраструктура)
   - [Сайт](#сайт)
   - [Мониторинг](#мониторинг)
   - [Логи](#логи)
   - [Сеть](#сеть)
   - [Резервное копирование](#резервное-копирование)
3. [Архитектура и принятые решения](#архитектура-и-принятые-решения)
   - [Сетевая структура и состав ВМ](#сетевая-структура-и-состав-вм)
   - [Сервисная модель](#сервисная-модель)
   - [Принятые компромиссы](#принятые-компромиссы)
4. [Используемые технологии](#используемые-технологии)
5. [Структура проекта](#структура-проекта)
6. [Визуальная архитектура проекта](#visual-architecture)
7. [Развёртывание](#развёртывание)
8. [Доступ к сервисам](#доступ-к-сервисам)
9. [Выводы](#выводы)
10. [Полезные команды](#полезные-команды)

---

## Задача

Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура размещается в Yandex Cloud.

Перед началом работы над курсовым заданием изучена [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).

---

## Инфраструктура

Для развёртки инфраструктуры использованы **Terraform** и **Ansible**.

### Сайт

- Созданы две ВМ (`web1`, `web2`) в разных зонах доступности (`ru-central1-a`, `ru-central1-b`).
- На каждой ВМ развернут сервер Nginx в Docker-контейнере. ОС и содержимое ВМ идентичны.
- Использован набор статичных файлов для сайта.
- Балансировка нагрузки реализована с помощью Nginx на Bastion (вместо Application Load Balancer) для соблюдения квоты на публичные IP-адреса.
- Тестирование сайта выполнено через `curl -v http://<публичный IP Bastion>:80`.

### Мониторинг

- Создана ВМ (`prometheus`) для Prometheus.
- На каждой веб-ВМ установлены **Node Exporter** и **Nginx Log Exporter**.
- Prometheus настроен на сбор метрик с этих экспортеров.
- Создана ВМ (`grafana`) для Grafana.
- Grafana настроена на взаимодействие с Prometheus. Настроены дашборды с отображением метрик: Utilization, Saturation, Errors для CPU, RAM, дисков, сети, а также `http_response_count_total` и `http_response_size_bytes`. Добавлены необходимые пороговые значения (tresholds).

> **Скриншот дашборда Grafana:**  
> ![Grafana Dashboard](img/grafana-dashboard.png)

### Логи

- Создана ВМ (`elasticsearch`) для Elasticsearch.
- На веб-серверах установлен Filebeat (в Docker-контейнере), настроена отправка access.log и error.log Nginx в Elasticsearch.
- Создана ВМ (`kibana`) для Kibana, сконфигурировано соединение с Elasticsearch.

> **Скриншот Kibana:**  
> ![Kibana](img/kibana.png)

### Сеть

- Развернут один VPC (`diplom-project-network`).
- Сервера web, Prometheus, Elasticsearch помещены в приватные подсети.
- Сервера Grafana и Kibana размещены в приватных подсетях, а Bastion — в публичной для обеспечения единственной точки входа.
- Настроены Security Groups для соответствующих сервисов на входящий трафик только к нужным портам.
- Настроена ВМ с публичным адресом (`bastion`), в которой открыт только один порт — 22 (SSH). Все Security Groups настроены на разрешение входящего SSH из этой security group. Реализована концепция bastion host.

### Резервное копирование

- Вместо платных снапшотов Yandex Cloud реализован бесплатный бэкап через **rsync** на Bastion.
- Настроена ежедневная задача (cron) для копирования важных файлов (`/etc`, `/var/log`, `/opt`, `/home/ubuntu`) в каталог `/opt/backup`.
- Ограничено время жизни бэкапов до 7 дней (автоматическая очистка старых копий).

---

## Архитектура и принятые решения

Визуальная схема взаимодействия компонентов системы представлена в разделе [Визуальная архитектура проекта](#visual-architecture).

### Сетевая структура и состав ВМ

- Создан один VPC с двумя зонами доступности.
- В каждой зоне имеются публичная подсеть (для Bastion) и приватная подсеть (для всех остальных сервисов).
- Для доступа в интернет из приватных подсетей настроен NAT-шлюз.
- Security Groups настроены по принципу минимально необходимых прав.

| Имя ВМ | Зона доступности | Роль | Публичный IP | Прерываемая |
|--------|------------------|------|--------------|-------------|
| `bastion` | `ru-central1-a` | SSH-шлюз, Nginx-прокси (балансировщик) | **Да** (единственный) | Да |
| `web1` | `ru-central1-a` | Веб-сервер (nginx в Docker) | Нет | Да |
| `web2` | `ru-central1-b` | Веб-сервер (nginx в Docker) | Нет | Да |
| `prometheus` | `ru-central1-a` | Сбор метрик (Prometheus в Docker) | Нет | Да |
| `grafana` | `ru-central1-a` | Визуализация (Grafana в Docker) | Нет | Да |
| `elasticsearch` | `ru-central1-a` | Хранилище логов (Elasticsearch в Docker) | Нет | Да |
| `kibana` | `ru-central1-a` | Просмотр логов (Kibana в Docker) | Нет | Да |

> **Примечание:** Все ВМ используют **прерываемые** инстансы (`preemptible = true`), что позволяет экономить до 70% стоимости аренды. Это допустимо для курсовой работы, так как инфраструктура не является критичной к перезапускам.

### Сервисная модель

- **Веб-серверы**: Nginx в Docker-контейнерах, балансировка через Nginx на Bastion.
- **Мониторинг**: Node Exporter и Nginx Log Exporter на веб-серверах; Prometheus собирает метрики; Grafana визуализирует их.
- **Логирование**: Filebeat (в Docker) на веб-серверах отправляет логи Nginx в Elasticsearch; Kibana предоставляет интерфейс для просмотра логов.
- **Резервное копирование**: Бесплатный бэкап через rsync на Bastion с хранением 7 дней.

### Принятые компромиссы

#### 1. Ограничение на количество публичных IP-адресов

- **Проблема**: Квота Yandex Cloud на скорость создания публичных IP (не более 1 IP в минуту). Создание нескольких публичных IP приводило к ошибке `rate exceeded`.
- **Решение**: Единственный публичный IP выделен только для Bastion. Все остальные сервисы размещены в приватных подсетях. Доступ к ним организован через Nginx-прокси на Bastion.
- **Результат**: Квота не превышается, безопасность повышена, доступ к сервисам сохранён.

#### 2. Отказ от Yandex Application Load Balancer

- **Проблема**: Создание балансировщика требует дополнительного публичного IP.
- **Решение**: Балансировка реализована с помощью Nginx на Bastion.
- **Компромисс**: Балансировщик не является управляемым сервисом Yandex Cloud, но это допустимо для курсовой работы и демонстрирует навыки администрирования.

#### 3. Размещение Grafana и Kibana в приватных подсетях

- **Проблема**: По заданию они должны быть в публичных подсетях, но это потребовало бы дополнительных публичных IP.
- **Решение**: Они размещены в приватных подсетях, доступ организован через прокси на Bastion. Это не ухудшает функциональность и повышает безопасность.

#### 4. Использование прерываемых (preemptible) ВМ

- **Решение**: Все ВМ созданы с параметром `preemptible = true`, что даёт экономию до 70% стоимости. Для курсовой работы это допустимо.

#### 5. Автоматизация SSH-доступа

- **Проблема**: На Bastion изначально не было приватного SSH-ключа для подключения к другим ВМ.
- **Решение**: Terraform передаёт публичный ключ на все ВМ через `ssh-keys`, а Ansible дополнительно распространяет ключи внутри сети. Доступ полностью автоматизирован.

#### 6. Отказ от управляемых сервисов Yandex Cloud (Managed Databases, Managed Kubernetes)

- **Проблема**: Использование управляемых сервисов упростило бы эксплуатацию, но увеличило бы стоимость и усложнило проект.
- **Решение**: Все сервисы (Prometheus, Grafana, Elasticsearch, Kibana) развёрнуты в Docker-контейнерах на собственных ВМ. Это даёт полный контроль над конфигурацией и снижает затраты.
- **Компромисс**: Нет автоматического масштабирования и failover, но для курсовой работы это приемлемо.

---

## Используемые технологии

| Технология / Компонент | Назначение | Примечание |
|------------------------|------------|------------|
| **Terraform** | Создание инфраструктуры (сети, ВМ, Security Groups). | Аутентификация через сервисный аккаунт с постоянным ключом (`service_account_key_file`). |
| **Ansible** | Настройка ВМ: установка Docker, запуск контейнеров, настройка экспортеров, Filebeat, сервисов мониторинга и логирования. | Используется динамический инвентарь, генерируемый Terraform. |
| **Docker** | Контейнеризация всех сервисов. | Изолирует и упрощает развёртывание приложений. |
| **Yandex Cloud CLI** | Создание сервисного аккаунта и авторизованного ключа, диагностика ресурсов. | Используется для ручных проверок и создания ключей. |
| **Git** | Управление версиями кода. | Репозиторий на GitHub: [MindMaze74/diplom-project](https://github.com/MindMaze74/diplom-project). |

### Стек сервисов (запущены в Docker)

| Сервис | Роль |
|--------|------|
| **Nginx (на Bastion)** | Балансировщик и прокси для сайта, Grafana и Kibana (единственная точка входа). |
| **Nginx (на web-серверах)** | Веб-сервер для статического сайта. |
| **Node Exporter** | Сбор системных метрик с веб-серверов для Prometheus. |
| **Nginx Log Exporter** | Сбор метрик доступа Nginx для Prometheus. |
| **Prometheus** | Сбор и хранение метрик мониторинга. |
| **Grafana** | Визуализация метрик (дашборды). |
| **Elasticsearch** | Хранилище логов от Filebeat. |
| **Kibana** | Просмотр и анализ логов. |
| **Filebeat** | Сбор и отправка логов Nginx в Elasticsearch. |

### Дополнительные инструменты

| Инструмент | Назначение |
|------------|------------|
| **Rsync** | Бесплатное резервное копирование важных файлов (ежедневно, хранение 7 дней). |
| **Cron** | Планировщик для автоматического запуска бэкапа. |
| **Nginx (на Bastion)** | Также выполняет роль балансировщика и прокси (отмечено выше). |

---

## Структура проекта

```bash
diplom-project
├── ansible
│   ├── ansible.cfg
│   ├── inventory
│   ├── playbooks
│   │   ├── backup.yml
│   │   ├── setup_bastion.yml
│   │   ├── setup_elasticsearch.yml
│   │   ├── setup_grafana.yml
│   │   ├── setup_kibana.yml
│   │   ├── setup_prometheus.yml
│   │   ├── setup_ssh_keys.yml
│   │   ├── setup_web_servers.yml
│   │   └── site.yml
│   └── templates
├── img
│   ├── img15.png
│   ├── img16.png
│   ├── img17.png
│   ├── img18.png
│   ├── img19.png
│   └── img20.png
├── md-instruction.md
├── README.md
├── screen-instruction.md
└── terraform
    ├── bastion-cloud-init.yml
    ├── bastion.tf
    ├── instances.tf
    ├── network.tf
    ├── outputs.tf
    ├── provider.tf
    ├── security-groups.tf
    ├── templates
    │   ├── bastion-cloud-init.yml.tpl
    │   ├── cloud-init.yml.tpl
    │   └── inventory.tpl
    ├── terraform.tfvars
    ├── terraform.tfvars.example
    ├── timeouts.tf
    └── variables.tf
```


---

## Визуальная архитектура проекта

На схеме ниже показано взаимодействие компонентов системы:

- **Сплошные стрелки** — прямой сетевой трафик между сервисами.
- **Пунктирные стрелки** — выход в интернет через NAT-шлюз.
- **Цифры** — номера портов для каждого соединения.

```mermaid
graph TD
    subgraph "Интернет"
        User[("Пользователь")]
    end

    subgraph "Yandex Cloud"
        subgraph "Публичная подсеть (10.0.10.0/24)"
            Bastion[("Bastion
(SSH-шлюз + Nginx-прокси)")]
            Bastion -->|"Порт 22"| User
        end

        subgraph "Приватная подсеть (10.0.1.0/24)"
            Web1[("Web1 (Nginx)")]
            Prometheus[("Prometheus")]
            Grafana[("Grafana")]
            Elasticsearch[("Elasticsearch")]
            Kibana[("Kibana")]
        end

        subgraph "Приватная подсеть (10.0.2.0/24)"
            Web2[("Web2 (Nginx)")]
        end

        subgraph "Маршрутизация"
            NAT[("NAT-шлюз")]
        end
    end

    User -->|"HTTP: 80,3000,5601"| Bastion
    Bastion -->|"Прокси :80"| Web1
    Bastion -->|"Прокси :80"| Web2
    Bastion -->|"Прокси :3000"| Grafana
    Bastion -->|"Прокси :5601"| Kibana

    Web1 -->|"Сбор метрик"| Prometheus
    Web2 -->|"Сбор метрик"| Prometheus
    Grafana -->|"Запросы к данным"| Prometheus

    Web1 -->|"Отправка логов"| Elasticsearch
    Web2 -->|"Отправка логов"| Elasticsearch
    Kibana -->|"Запросы к данным"| Elasticsearch

    Web1 -.->|"Доступ в интернет"| NAT
    Web2 -.->|"Доступ в интернет"| NAT
    Prometheus -.->|"Доступ в интернет"| NAT
    Grafana -.->|"Доступ в интернет"| NAT
    Elasticsearch -.->|"Доступ в интернет"| NAT
    Kibana -.->|"Доступ в интернет"| NAT
    Bastion -.->|"Доступ в интернет"| NAT
```


## Развёртывание

### Предварительные требования
Перед началом убедитесь, что у вас есть:

Активный платёжный аккаунт в Yandex Cloud с достаточным балансом.

Установленные инструменты:

Terraform (>= 1.0) — [инструкция по установке](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
Ansible (>= 2.9) — [инструкция по установке](https://docs.ansible.com/projects/ansible/latest/installation_guide/intro_installation.html)
Yandex Cloud CLI — [инструкция по установке](https://yandex.cloud/ru/docs/cli/operations/install-cli?utm_referrer=about%3Ablank)
Настроенный профиль Yandex Cloud CLI — выполните yc init и авторизуйтесь.
Права доступа - ваш аккаунт должен иметь роль editor или выше в каталоге, где будут создаваться ресурсы.
Сервисный аккаунт с авторизованным ключом (путь к ключу указывается в terraform.tfvars).
SSH-ключи на локальной машине (~/.ssh/diplom и ~/.ssh/diplom.pub).

### Шаги по развёртыванию

1.  **Клонировать репозиторий**:
    ```bash
    git clone https://github.com/MindMaze74/diplom-project.git
    cd diplom-project
    ```

2.  **Настроить переменные Terraform**:
    ```bash
    cd terraform
    cp terraform.tfvars.example terraform.tfvars
    ```
   >Отредактируйте файл terraform.tfvars, указав свои данные (ID облака, каталога, пути к ключам).

3.  **Проверить версии инструментов (рекомендуется)**:
    ```bash
    terraform --version
    ansible --version
    yc --version
    ```
4.  **Развернуть инфраструктуру**:
    ```bash
    terraform init
    terraform apply -parallelism=1
    ```
   > Дождитесь завершения (около 10–15 минут). При появлении запроса подтвердите действие вводом yes
   > Примечание: Параметр -parallelism=1 ограничивает параллельность для обхода квоты на создание публичных IP-адресов.

5.  **Проверить созданные ресурсы**:
    ```bash
    terraform state list
    terraform output
    ```
6.  **Настроить сервисы через Ansible**:
     ```bash
    cd ../ansible
    ansible-playbook -i inventory/inventory.ini playbooks/site.yml
    ```
    >Это займёт ещё 5–10 минут.

7.  **Проверить логи Ansible (если возникли ошибки)**:
    ```bash
    ansible-playbook -i inventory/inventory.ini playbooks/site.yml -vvv
    ```
8.  **Проверить доступность сервисов (см. раздел Доступ к сервисам).**


#### Доступ к сервисам

| Сервис | URL | Логин/Пароль |
|--------|-----|--------------|
| **Сайт** | `http://<bastion_public_ip>/` | – |
| **Grafana** | `http://<bastion_public_ip>:3000` | `admin` / `admin` |
| **Kibana** | `http://<bastion_public_ip>:5601` | – (без аутентификации) |
>Важно:
>Доступ осуществляется по протоколу HTTP (HTTPS не настроен).
> Публичный IP Bastion можно получить командой:
> ```bash
> cd terraform
> terraform output bastion_public_ip
> ```
>Kibana может быть недоступна в течение первых 2–3 минут после запуска, так как ей требуется время для инициализации.

### Вывод
В результате работы спроектирована и реализована полностью автоматизированная инфраструктура, отвечающая минимальным требованиям курсового задания. Использование Terraform и Ansible обеспечивает воспроизводимость, а принятые компромиссы (единственный публичный IP, прокси на Bastion, прерываемые ВМ, отказ от управляемых сервисов) являются разумными и обоснованными в условиях облачных квот и ограниченного бюджета.

Инфраструктура готова к масштабированию: добавление новых веб-серверов или увеличение ресурсов ВМ не требует изменения архитектуры. Проект может служить основой для более сложных решений с использованием Managed Kubernetes, Managed Databases и других сервисов Yandex Cloud.

## Полезные команды

### Terraform

```bash
# Инициализация проекта
terraform init

# Проверка синтаксиса и форматирование
terraform validate
terraform fmt

# Просмотр плана изменений
terraform plan

# Развёртывание инфраструктуры (с ограничением параллельности)
terraform apply -parallelism=1

# Удаление всей инфраструктуры
terraform destroy -parallelism=1

# Получение выходных данных (IP-адреса)
terraform output bastion_public_ip
terraform output web_private_ips
```

### Ansible
```bash
# Проверка синтаксиса плейбука
ansible-playbook --syntax-check playbooks/site.yml

# Запуск основного плейбука
ansible-playbook -i inventory/inventory.ini playbooks/site.yml

# Запуск конкретного плейбука (например, только для веб-серверов)
ansible-playbook -i inventory/inventory.ini playbooks/setup_web_servers.yml --limit web1,web2

# Запуск с тегом (например, только Docker)
ansible-playbook -i inventory/inventory.ini playbooks/site.yml --tags docker

# Просмотр инвентаря
ansible-inventory -i inventory/inventory.ini --list

# Отладка с подробным выводом
ansible-playbook -i inventory/inventory.ini playbooks/site.yml -vvv
```

### Yandex Cloud CLI
```bash
# Создание сервисного аккаунта
yc iam service-account create --name diplom-sa

# Создание авторизованного ключа
yc iam key create --service-account-name diplom-sa --output ~/diplom-sa-key.json

# Назначение роли editor на каталог
yc resource-manager folder add-access-binding \
  --id <ваш_folder_id> \
  --role editor \
  --service-account-name diplom-sa

# Список всех ресурсов в каталоге (ВМ, сети, диски)
yc compute instance list --folder-id <ваш_folder_id>
yc vpc network list --folder-id <ваш_folder_id>
yc compute disk list --folder-id <ваш_folder_id>

# Список публичных IP-адресов
yc vpc address list --folder-id <ваш_folder_id>
```

### Docker (на ВМ)
```bash
# Просмотр всех запущенных контейнеров
docker ps

# Просмотр всех контейнеров (включая остановленные)
docker ps -a

# Логи контейнера (например, Kibana)
docker logs kibana --tail 50

# Перезапуск контейнера
docker restart elasticsearch

# Остановка и удаление контейнера
docker stop kibana && docker rm kibana

# Запуск контейнера с нужными переменными окружения
docker run -d \
  --name kibana \
  --restart always \
  -p 5601:5601 \
  -e ELASTICSEARCH_HOSTS='["http://<elasticsearch_private_ip>:9200"]' \
  docker.elastic.co/kibana/kibana:8.17.0
```

### Проверка работоспособности
```bash
# Проверка сайта через Bastion
curl -v http://<bastion_public_ip>:80

# Проверка Grafana
curl -v http://<bastion_public_ip>:3000

# Проверка Kibana
curl -v http://<bastion_public_ip>:5601

# Проверка Elasticsearch (внутренний доступ)
curl http://<elasticsearch_private_ip>:9200

# Проверка метрик Nginx Log Exporter
curl http://<web1_private_ip>:4040/metrics | grep nginx_http

# Проверка индексов в Elasticsearch (логи)
curl http://<elasticsearch_private_ip>:9200/_cat/indices
```

### Диагностика SSH-доступа через Bastion
```bash
# Подключение к Bastion
ssh -i ~/.ssh/diplom ubuntu@<bastion_public_ip>

# Проверка доступа к web1
ssh -i ~/.ssh/diplom ubuntu@<web1_private_ip> "hostname"

# Копирование SSH-ключа на все ВМ
ssh-copy-id -i ~/.ssh/diplom.pub ubuntu@<web1_private_ip>
```

### Резервное копирование (rsync)
```bash
# Ручной запуск бэкапа
sudo /usr/local/bin/backup.sh

# Просмотр созданных бэкапов
ls -la /opt/backup/$(hostname)/

# Просмотр логов бэкапа
sudo tail -f /var/log/backup.log
```

### Git
```bash
# Клонирование репозитория
git clone https://github.com/MindMaze74/diplom-project.git

# Статус изменений
git status

# Добавление всех изменений
git add .

# Коммит с сообщением
git commit -m "Описание изменений"

# Отправка в удалённый репозиторий
git push origin main
```