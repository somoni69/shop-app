# 🛍️ Flutter ShopApp

Интернет-магазин на Flutter с управлением состоянием через Provider. Приложение построено на основе архитектуры MVVM и включает список товаров, корзину и управление навигацией.

---

## 🚀 Основные функции:

- 📦 Отображение списка товаров
- 🛒 Добавление и удаление товаров из корзины
- 📊 Подсчет общей суммы корзины
- 🧠 Управление состоянием с использованием `Provider`
- 💅 Используется `Material 3` (современный дизайн)

---

## 🧰 Используемые технологии:

- **Flutter**
- **Provider** (состояние)
- **Material 3**
- **Routing (Navigator 1.0)**

---

## 💡 Скриншоты:
<img width="256" height="560" alt="image" src="https://github.com/user-attachments/assets/730f01bc-3637-4e63-b514-10e9ae293765" />
<img width="247" height="547" alt="image" src="https://github.com/user-attachments/assets/de66390d-9366-4851-920a-901de287484d" />

```markdown
## 📁 Структура проекта:

```plaintext
lib/
├── main.dart                   # Точка входа
├── providers/
│   ├── cart_provider.dart      # Состояние корзины
│   └── products_provider.dart  # Состояние товаров
├── screens/
│   ├── product_list_screen.dart # Главный экран со списком товаров
│   └── cart_screen.dart         # Экран корзины
├── models/
│   └── product.dart            # Модель товара (если есть)
