# nproject-kuber

DevOps-инфраструктура для домена **nproject.site** на **Yandex Cloud**.

## Состав
- **Terraform**: VPC, DNS-зона, Container Registry, Kubernetes (Yandex Managed Service for Kubernetes)
- **GitHub Actions**: CI/CD pipeline — автоматическое применение инфраструктуры и деплой приложения
- **Приложение**: Python + FastAPI (или другой фреймворк) в Docker-контейнере
- **Kubernetes**: Deployment, Service (LoadBalancer), Ingress (HTTP)

## CI/CD workflow
Запускается при пуше в ветку `main`:
1. Применяется Terraform (`terraform apply`)
2. Собирается и пушится Docker-образ в Yandex Container Registry
3. Деплоится в Kubernetes
4. Обновляются A-записи в DNS (через повторный `terraform apply`)

## Требования
- Terraform ≥ 1.5
- Домен `nproject.site` делегирован в Yandex DNS
- Настроены секреты в GitHub: `YC_TOKEN`, `YC_CLOUD_ID`, `YC_FOLDER_ID`, `YC_ACCESS_KEY_ID`, `YC_SECRET_ACCESS_KEY`

## Безопасность
- Все секреты передаются через GitHub Secrets
- Terraform state хранится в Yandex Object Storage (S3-совместимый бэкенд)

## Разработка
Работай в feature-ветках. Все изменения тестируй в изолированной ветке перед слиянием в `main`.