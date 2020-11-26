// ----------------------------------------------------------
// This Source Code Form is subject to the terms of the
// Mozilla Public License, v.2.0. If a copy of the MPL
// was not distributed with this file, You can obtain one
// at http://mozilla.org/MPL/2.0/.
// ----------------------------------------------------------
// Codebase: https://github.com/ArKuznetsov/irac/
// ----------------------------------------------------------

Перем Кластер_Агент;
Перем Кластер_Владелец;
Перем ИБ_Владелец;

Перем ПараметрыОбъекта;

Перем Элементы;
Перем Лицензии;

Перем Лог;

// Конструктор
//   
// Параметры:
//   АгентКластера  - АгентКластера         - ссылка на родительский объект агента кластера
//   Кластер        - Кластер               - ссылка на родительский объект кластера
//   ИБ             - ИнформационнаяБаза    - ссылка на родительский объект информационной базы
//
Процедура ПриСозданииОбъекта(АгентКластера, Кластер, ИБ = Неопределено)

	Лог = Служебный.Лог();

	Кластер_Агент = АгентКластера;
	Кластер_Владелец = Кластер;
	ИБ_Владелец = ИБ;

	ПараметрыОбъекта = Новый КомандыОбъекта(Кластер_Агент, Перечисления.РежимыАдминистрирования.Сеансы);

	ПараметрыЛицензий = Новый КомандыОбъекта(Кластер_Агент, Перечисления.РежимыАдминистрирования.ЛицензииСеансов);

	Элементы = Новый ОбъектыКластера(ЭтотОбъект);
	Лицензии = Новый Лицензии(Кластер_Агент, Кластер_Владелец, ЭтотОбъект, ИБ_Владелец);

КонецПроцедуры // ПриСозданииОбъекта()

// Процедура получает список сеансов от утилиты администрирования кластера 1С
// и сохраняет в локальных переменных
//   
// Параметры:
//   ОбновитьПринудительно        - Булево    - Истина - принудительно обновить данные (вызов RAC)
//                                            - Ложь - данные будут получены если истекло время актуальности
//                                                     или данные не были получены ранее
//   
Процедура ОбновитьДанные(ОбновитьПринудительно = Ложь) Экспорт
	
	Если НЕ Элементы.ТребуетсяОбновление(ОбновитьПринудительно) Тогда
		Возврат;
	КонецЕсли;

	ПараметрыКоманды = Новый Соответствие();
	ПараметрыКоманды.Вставить("СтрокаПодключенияАгента"     , Кластер_Агент.СтрокаПодключения());
	ПараметрыКоманды.Вставить("ИдентификаторКластера"       , Кластер_Владелец.Ид());
	ПараметрыКоманды.Вставить("ПараметрыАвторизацииКластера", Кластер_Владелец.ПараметрыАвторизации());
	
	Если НЕ ИБ_Владелец = Неопределено Тогда
		ПараметрыКоманды.Вставить("ИдентификаторИБ", ИБ_Владелец.Ид());
	КонецЕсли;

	ПараметрыОбъекта.УстановитьЗначенияПараметровКоманд(ПараметрыКоманды);

	КодВозврата = ПараметрыОбъекта.ВыполнитьКоманду("Список");
	
	Если НЕ КодВозврата = 0 Тогда
		ВызватьИсключение СтрШаблон("Ошибка получения списка сеансов, КодВозврата = %1: %2",
	                                КодВозврата,
	                                Кластер_Агент.ВыводКоманды(Ложь));
	КонецЕсли;
	
	МассивРезультатов = Кластер_Агент.ВыводКоманды();

	МассивСеансов = Новый Массив();
	Для Каждого ТекОписание Из МассивРезультатов Цикл
		МассивСеансов.Добавить(Новый Сеанс(Кластер_Агент, Кластер_Владелец, ИБ_Владелец, ТекОписание));
	КонецЦикла;

	Элементы.Заполнить(МассивСеансов);

	Элементы.УстановитьАктуальность();

КонецПроцедуры // ОбновитьДанные()

// Функция возвращает коллекцию параметров объекта
//   
// Параметры:
//   ИмяПоляКлюча         - Строка    - имя поля, значение которого будет использовано
//                                      в качестве ключа возвращаемого соответствия
//   
// Возвращаемое значение:
//    Соответствие - коллекция параметров объекта, для получения/изменения значений
//
Функция ПараметрыОбъекта(ИмяПоляКлюча = "Имя") Экспорт

	Возврат ПараметрыОбъекта.ОписаниеСвойств(ИмяПоляКлюча);

КонецФункции // ПараметрыОбъекта()

// Функция возвращает список сеансов
//   
// Параметры:
//   Отбор                    - Структура    - Структура отбора сеансов (<поле>:<значение>)
//   ОбновитьПринудительно    - Булево       - Истина - принудительно обновить данные (вызов RAC)
//   ЭлементыКакСоответствия  - Булево,      - Истина - элементы результата будут преобразованы в соответствия
//                              Строка         с именами свойств в качестве ключей
//                                             <Имя поля> - элементы результата будут преобразованы в соответствия
//                                             со значением указанного поля в качестве ключей ("Имя"|"ИмяРАК")
//                                             Ложь - (по умолчанию) элементы будут возвращены как есть
//
// Возвращаемое значение:
//    Массив - список сеансов
//
Функция Список(Отбор = Неопределено, ОбновитьПринудительно = Ложь, ЭлементыКакСоответствия = Ложь) Экспорт

	Сеансы = Элементы.Список(Отбор, ОбновитьПринудительно, ЭлементыКакСоответствия);
	
	Возврат Сеансы;

КонецФункции // Список()

// Функция возвращает список сеансов
//   
// Параметры:
//   ПоляИерархии             - Строка       - Поля для построения иерархии списка сеансов, разделенные ","
//   ОбновитьПринудительно    - Булево       - Истина - принудительно обновить данные (вызов RAC)
//   ЭлементыКакСоответствия  - Булево,      - Истина - элементы результата будут преобразованы в соответствия
//                              Строка         с именами свойств в качестве ключей
//                                             <Имя поля> - элементы результата будут преобразованы в соответствия
//                                             со значением указанного поля в качестве ключей ("Имя"|"ИмяРАК")
//                                             Ложь - (по умолчанию) элементы будут возвращены как есть
//
// Возвращаемое значение:
//    Соответствие - список сеансов
//
Функция ИерархическийСписок(Знач ПоляИерархии, ОбновитьПринудительно = Ложь, ЭлементыКакСоответствия = Ложь) Экспорт

	Сеансы = Элементы.ИерархическийСписок(ПоляИерархии, ОбновитьПринудительно, ЭлементыКакСоответствия);

	Возврат Сеансы;

КонецФункции // ИерархическийСписок()

// Функция возвращает количество сеансов в списке
//   
// Возвращаемое значение:
//    Число - количество сеансов
//
Функция Количество() Экспорт

	Если Элементы = Неопределено Тогда
		Возврат 0;
	КонецЕсли;
	
	Возврат Элементы.Количество();

КонецФункции // Количество()

// Функция возвращает описание сеанса кластера 1С
//   
// Параметры:
//   Сеанс                   - Строка    - Номер сеанса в виде <имя информационной базы>:<номер сеанса>
//   ОбновитьПринудительно   - Булево    - Истина - принудительно обновить данные (вызов RAC)
//   КакСоответствие         - Булево    - Истина - результат будет преобразован в соответствие
//
// Возвращаемое значение:
//    Соответствие - описание сеанса 1С
//
Функция Получить(Знач Сеанс, Знач ОбновитьПринудительно = Ложь, КакСоответствие = Ложь) Экспорт

	Сеанс = СтрРазделить(Сеанс, ":", Ложь);

	Если Сеанс.Количество() = 1 Тогда
		Если Служебный.ЭтоЧисло(Сеанс[0]) Тогда
			Если ИБ_Владелец = Неопределено Тогда
				Возврат Неопределено;
			КонецЕсли;
			Сеанс.Вставить(0, ИБ_Владелец.Получить("name"));
		Иначе
			Сеанс.Добавить("1");
		КонецЕсли;
	КонецЕсли;

	ИБ = Кластер_Владелец.ИнформационныеБазы().Получить(СокрЛП(Сеанс[0]));

	Отбор = Новый Соответствие();
	Отбор.Вставить("infobase"  ,  ИБ.Получить("infobase"));
	Отбор.Вставить("session-id", Число(СокрЛП(Сеанс[1])));

	Сеансы = Элементы.Список(Отбор, ОбновитьПринудительно, КакСоответствие);

	Если Сеансы.Количество() = 0 Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Возврат Сеансы[0];

КонецФункции // Получить()

// Процедура удаляет сеанс
//   
// Параметры:
//   Сеанс     - Сеанс, Строка   - Сеанс или номер сеанса в виде <имя информационной базы>:<номер сеанса>
//
Процедура Удалить(Знач Сеанс) Экспорт
	
	Если ТипЗнч(Сеанс) = Тип("Строка") Тогда
		Сеанс = Получить(Сеанс);
	КонецЕсли;

	Сеанс.Завершить();

	ОбновитьДанные(Истина);

КонецПроцедуры // Удалить()

// Функция возвращает список лицензий сеансов 1С
//   
// Параметры:
//   ОбновитьПринудительно   - Булево    - Истина - обновить данные лицензий (вызов RAC)
//
// Возвращаемое значение:
//    ОбъектыКластера - список лицензий сеансов 1С
//
Функция Лицензии(ОбновитьПринудительно = Ложь) Экспорт
	
	Возврат Лицензии;
	
КонецФункции // Лицензии()
