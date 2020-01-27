<H2>Kubernetes-Security</H2>

## task01:\
01-bob.yaml - добавление ServiceAccount и биндинг сервисных аккаунтов к существующим ролям\
02-dave.yaml - добавление новой роли без прав доступа\

## 02-task:\
01-namespace.yaml - создание namespace prometheus :\
02-user.yaml - добавление пользователя carol к этому namespace\
03-rules.yaml - Даем права get, list, watch\

## 03-task:\
3.1. 01-namespace.yaml - namespace dev
3.2. 02-jane.yaml - SA jane
3.3. 03-jane-admin.yaml - назначем jane роль admin для dev
3.4. 04-ken.yaml создаем SA ken
3.5. 05-ken-view.yaml - даем права SA ken только на чтение в dev