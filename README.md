# Сдача проектной работы 8 спринта

---

## Задание 1. Проектирование технологической архитектуры

См. файлы в папке Task1:

- [`drawio`](<Task1/InureTech_технологическая архитектура_to-be.drawio>)
- [`svg-вариант`](<Task1/InureTech_технологическая архитектура_to-be.drawio.svg>)
- [`png-вариант`](<Task1/InureTech_технологическая архитектура_to-be.drawio.png>)

---

## Задание 2. Динамическое масштабирование контейнеров

Команды по запуску и настройке кластера с деплоем приложения представлены в [Makefile](Makefile).

Скрины, демонстрирующие успешный процесс автомасштабирования контейнеров:

### Веб-интерфейс minikube dashboard, демонстрирующий несколько под (pods):

![1.png](Task2/screens/1.png)

### Веб-интерфейс minikube dashboard, демонстрирующий несколько под (workload):

![2.png](Task2/screens/2.png)

### Веб-интерфейс locust, демонстрирующий рост нагрузки:

![3.png](Task2/screens/3.png)

### Скрин статуса HPA (kubectl):

![4.png](Task2/screens/4.png)

### Ивенты HPA, среди которых есть события "rescale" (kubectl):

![5.png](Task2/screens/5.png)

### Поды (kubectl):

![6.png](Task2/screens/6.png)

---

## Задание 3. Переход на Event-Driven архитектуру

См. файлы в папке Task3:

- [`RISKS.md`](<Task3/RISKS.md>)
- [`С4.drawio`](<Task3/InsureTech_C4_сontainer-diagram.drawio.xml>)
- [`C4.png`](<Task3/InsureTech_C4_сontainer-diagram.drawio.png>)
- [`C4.svg`](<Task3/InsureTech_C4_сontainer-diagram.drawio.svg>)

### Что перевели на Event-Streaming

* **Публикация каталога продуктов/тарифов**:
  `ins-product-aggregator → Kafka` (`ins.products.*`) - агрегатор в фоне собирает/нормализует данные страховых и публикует снапшоты/дельты.
* **Локальные реплики каталога**:
  `core-app ← Kafka (products.*)` и `ins-comp-settlement ← Kafka (products.*)` - оба сервиса подписываются и поддерживают свои read-модели без периодических REST-пуллов.
* **Доменные события по полисам**:
  `core-app → Kafka (policies.*)` - при оформлении/изменении/отмене полиса;
  `ins-comp-settlement ← Kafka (policies.*)` - потребляет события вместо ночного REST.

### Будем ли использовать Transactional Outbox

**Да.**

* В **`ins-product-aggregator`** и **`core-app`** применяем `Transactional Outbox`: запись бизнес-состояния и запись «события» фиксируются одной транзакцией в БД (таблица `outbox`), отдельный relay публикует в Kafka с ретраями и идемпотентностью.
* Консьюмеры выполняют идемпотентные `upsert`-ы / дедупликацию по ключу события.
* В **`ins-comp-settlement`** outbox не обязателен (он потребитель), если только сервис сам не будет издавать новые доменные события.

### Что осталось REST и почему пунктир

* **`core-app ↔ ins-product-aggregator` - REST fallback (пунктир)**:
  используется только при необходимости (например, оперативная проверка/принудительное обновление из кеша агрегатора, когда стрим ещё не догнал).
* **`ins-comp-settlement → core-app` - REST reconciliation (пунктир)**:
  разовые сверки/перезапуски отчётности в исключительных случаях. Основной поток - события `products.*` и `policies.*`.

---
