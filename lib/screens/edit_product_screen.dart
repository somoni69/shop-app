// lib/screens/edit_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/products_provider.dart';
import '../services/storage_service.dart';

class EditProductScreen extends StatefulWidget {
  static const routeName = '/edit-product';
  const EditProductScreen({super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = StorageService();

  var _editedProduct = Product(
    id: '',
    title: '',
    price: 0.0,
    description: '',
    images: [],
    category: 'electronics',
    rating: 0.0,
    sellerId: '',
  );

  var _initValues = {
    'title': '',
    'description': '',
    'price': '',
  };

  bool _isLoading = false;
  bool _isInit = true;
  String _appBarTitle = 'Добавить товар';

  List<File> _pickedImages = [];
  List<String> _existingImageUrls = []; // <-- Эта переменная была, но мы ее не заполняли

  @override
  void didChangeDependencies() {
    if (_isInit) {
      final productId = ModalRoute.of(context)?.settings.arguments as String?;

      if (productId != null) {
        _appBarTitle = 'Редактировать товар';
        _editedProduct =
            Provider.of<ProductsProvider>(context, listen: false).findById(productId);
        _initValues = {
          'title': _editedProduct.title,
          'description': _editedProduct.description,
          'price': _editedProduct.price.toString(),
        };
        // --- ИСПРАВЛЕНИЕ ЗДЕСЬ ---
        // Заполняем список существующих URL-адресов
        _existingImageUrls = List<String>.from(_editedProduct.images);
        // --- КОНЕЦ ИСПРАВЛЕНИЯ ---
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      imageQuality: 70,
    );
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _pickedImages = pickedFiles.map((file) => File(file.path)).toList();
        // Когда выбрали новые фото, очищаем старые URL,
        // чтобы в превью отображались только НОВЫЕ.
        _existingImageUrls = [];
      });
    }
  }

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    if (_pickedImages.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите хотя бы 1 изображение.')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      List<String> finalImageUrls = [];

      if (_pickedImages.isNotEmpty) {
        print('Загрузка ${_pickedImages.length} новых изображений...');
        finalImageUrls =
            await _storageService.uploadMultipleProductImages(_pickedImages);
        // TODO: Удалить старые фото из Storage
      } else {
        print('Новые изображения не выбраны, оставляем старые.');
        finalImageUrls = _existingImageUrls;
      }

      final productToSave = Product(
        id: _editedProduct.id,
        title: _editedProduct.title,
        price: _editedProduct.price,
        description: _editedProduct.description,
        images: finalImageUrls,
        category: _editedProduct.category,
        rating: _editedProduct.rating,
        sellerId: _editedProduct.sellerId,
      );

      final productsProvider =
          Provider.of<ProductsProvider>(context, listen: false);

      if (productToSave.id.isNotEmpty) {
        await productsProvider.updateProduct(productToSave);
      } else {
        await productsProvider.addProduct(productToSave);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('Произошла ошибка!'),
                content: Text(e.toString()),
                actions: [
                  TextButton(
                      child: const Text('Ок'),
                      onPressed: () => Navigator.of(ctx).pop())
                ],
              ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildImagePreview() {
    // --- УЛУЧШЕНИЕ ЛОГИКИ ПРЕВЬЮ ---
    // Если выбраны новые фото, показываем ИХ
    if (_pickedImages.isNotEmpty) {
      print('Показ превью ${_pickedImages.length} НОВЫХ изображений');
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _pickedImages.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
        itemBuilder: (ctx, i) =>
            Image.file(_pickedImages[i], fit: BoxFit.cover),
      );
    }
    // Если новых фото нет, но есть СТАРЫЕ (при редактировании), показываем ИХ
    if (_existingImageUrls.isNotEmpty) {
      print('Показ превью ${ _existingImageUrls.length} СТАРЫХ изображений');
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _existingImageUrls.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
        itemBuilder: (ctx, i) =>
            Image.network(_existingImageUrls[i], fit: BoxFit.cover),
      );
    }
    // Если фото нет
    print('Превью: Нет изображений');
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: const Center(child: Text('Выберите фото')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      initialValue: _initValues['title'],
                      decoration: const InputDecoration(labelText: 'Название'),
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Введите название.' : null,
                      onSaved: (value) {
                        _editedProduct = Product(
                          id: _editedProduct.id, title: value!, price: _editedProduct.price,
                          description: _editedProduct.description, images: _editedProduct.images,
                          category: _editedProduct.category, rating: _editedProduct.rating, sellerId: _editedProduct.sellerId,
                        );
                      },
                    ),
                    TextFormField(
                      initialValue: _initValues['price'],
                      decoration: const InputDecoration(labelText: 'Цена'),
                      textInputAction: TextInputAction.next,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Введите цену.';
                        if (double.tryParse(value) == null) return 'Введите корректное число.';
                        if (double.parse(value) <= 0) return 'Цена должна быть больше нуля.';
                        return null;
                      },
                      onSaved: (value) {
                        _editedProduct = Product(
                          id: _editedProduct.id, title: _editedProduct.title, price: double.parse(value!),
                          description: _editedProduct.description, images: _editedProduct.images,
                          category: _editedProduct.category, rating: _editedProduct.rating, sellerId: _editedProduct.sellerId,
                        );
                      },
                    ),
                    TextFormField(
                      initialValue: _initValues['description'],
                      decoration: const InputDecoration(labelText: 'Описание'),
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Введите описание.' : null,
                      onSaved: (value) {
                        _editedProduct = Product(
                          id: _editedProduct.id, title: _editedProduct.title, price: _editedProduct.price,
                          description: value!, images: _editedProduct.images,
                          category: _editedProduct.category, rating: _editedProduct.rating, sellerId: _editedProduct.sellerId,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildImagePreview(), // Используем наш новый виджет
                    TextButton.icon(
                      icon: const Icon(Icons.image),
                      // --- ИЗМЕНЕНИЕ ТЕКСТА КНОПКИ ---
                      label: Text(_existingImageUrls.isNotEmpty 
                          ? 'Выбрать НОВЫЕ фото (заменят старые)' 
                          : 'Выбрать фото'),
                      onPressed: _pickImages,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}