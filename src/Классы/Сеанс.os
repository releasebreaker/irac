// ----------------------------------------------------------
// This Source Code Form is subject to the terms of the
// Mozilla Public License, v.2.0. If a copy of the MPL
// was not distributed with this file, You can obtain one
// at http://mozilla.org/MPL/2.0/.
// ----------------------------------------------------------
// Codebase: https://github.com/ArKuznetsov/irac/
// ----------------------------------------------------------

Перем Сеанс_Ид;            // session
Перем Сеанс_Свойства;
Перем Сеанс_Лицензии;

Перем Кластер_Агент;
Перем Кластер_Владелец;
Перем ИБ_Владелец;

Перем ПараметрыОбъекта;

Перем ПериодОбновления;
Перем МоментАктуальности;

Перем Лог;

// Конструктор
//   
// Параметры:
//   АгентКластера      - АгентКластера             - ссылка на родительский объект агента кластера
//   Кластер            - Кластера                  - ссылка на родительский объект кластера
//   ИБ                 - ИнформационнаяБаза        - ссылка на родительский объект информационной базы
//   Сеанс              - Строка, Соответствие      - идентификатор сеанса или параметры сеанса
//
Процедура ПриСозданииОбъекта(АгентКластера, Кластер, ИБ, Сеанс)

	Лог = Служебный.Лог();

	Если НЕ ЗначениеЗаполнено(Сеанс) Тогда
		Возврат;
	КонецЕсли;

	ПараметрыОбъекта = Новый КомандыОбъекта(Перечисления.РежимыАдминистрирования.Сеансы);

	ПараметрыЛицензий = Новый КомандыОбъекта(Перечисления.РежимыАдминистрирования.ЛицензииСеансов);

	Кластер_Агент = АгентКластера;
	Кластер_Владелец = Кластер;
	ИБ_Владелец = ИБ;
	
	Если ТипЗнч(Сеанс) = Тип("Соответствие") Тогда
		Сеанс_Ид = Сеанс["session"];
		Служебный.ЗаполнитьСвойстваОбъекта(ЭтотОбъект, Сеанс_Свойства, Сеанс);
		МоментАктуальности = ТекущаяУниверсальнаяДатаВМиллисекундах();
	Иначе
		Сеанс_Ид = Сеанс;
		МоментАктуальности = 0;
	КонецЕсли;

	ПериодОбновления = 60000;
	
	Сеанс_Лицензии = Новый Лицензии(Кластер_Агент, Кластер_Владелец, ЭтотОбъект, ИБ_Владелец);

КонецПроцедуры // ПриСозданииОбъекта()

// Процедура получает данные от сервиса администрирования кластера 1С
// и сохраняет в локальных переменных
//   
// Параметры:
//   ОбновитьПринудительно      - Булево    - Истина - принудительно обновить данные (вызов RAC)
//                                          - Ложь - данные будут получены если истекло время актуальности
//                                                   или данные не были получены ранее
//   
Процедура ОбновитьДанные(ОбновитьПринудительно = Ложь) Экспорт

	Если НЕ Служебный.ТребуетсяОбновление(Сеанс_Свойства,
		МоментАктуальности, ПериодОбновления, ОбновитьПринудительно) Тогда
		 Возврат;
	 КонецЕсли;
 
	 ПараметрыКоманды = Новый Соответствие();
	ПараметрыКоманды.Вставить("СтрокаПодключенияАгента"   , Кластер_Агент.СтрокаПодключения());
	ПараметрыКоманды.Вставить("ИдентификаторКластера"     , Кластер_Владелец.Ид());
	ПараметрыКоманды.Вставить("СтрокаАвторизацииКластера" , Кластер_Владелец.СтрокаАвторизации());
	ПараметрыКоманды.Вставить("ИдентификаторСеанса"       , Ид());

	ПараметрыОбъекта.УстановитьЗначенияПараметровКоманд(ПараметрыКоманды);

	КодВозврата = Кластер_Агент.ВыполнитьКоманду(ПараметрыОбъекта.ПараметрыКоманды("Описание"));

	Если НЕ КодВозврата = 0 Тогда
		ВызватьИсключение СтрШаблон("Ошибка получения описания сеанса, КодВозврата = %1: %2",
	                                КодВозврата,
	                                Кластер_Агент.ВыводКоманды(Ложь));
	КонецЕсли;
	
	МассивРезультатов = Кластер_Агент.ВыводКоманды();

	Если МассивРезультатов.Количество() = 0 Тогда
		Возврат;
	КонецЕсли;
	
	Служебный.ЗаполнитьСвойстваОбъекта(ЭтотОбъект, Сеанс_Свойства, МассивРезультатов[0]);

	МоментАктуальности = ТекущаяУниверсальнаяДатаВМиллисекундах();

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

// Функция возвращает идентификатор сеанса 1С
//   
// Возвращаемое значение:
//    Строка - идентификатор сеанса 1С
//
Функция Ид() Экспорт

	Возврат Сеанс_Ид;

КонецФункции // Ид()

// Функция возвращает значение параметра сеанса 1С
//   
// Параметры:
//   ИмяПоля                 - Строка        - Имя параметра сеанса
//   ОбновитьПринудительно   - Булево        - Истина - обновить список (вызов RAC)
//
// Возвращаемое значение:
//    Произвольный - значение параметра сеанса 1С
//
Функция Получить(ИмяПоля, ОбновитьПринудительно = Ложь) Экспорт
	
	ОбновитьДанные(ОбновитьПринудительно);

	Если НЕ Найти(ВРег("Ид, session"), ВРег(ИмяПоля)) = 0 Тогда
		Возврат Сеанс_Ид;
	КонецЕсли;
	
	ЗначениеПоля = Сеанс_Свойства.Получить(ИмяПоля);

	Если ЗначениеПоля = Неопределено Тогда
	    
		ОписаниеПараметра = ПараметрыОбъекта("ИмяРАК").Получить(ИмяПоля);

		Если НЕ ОписаниеПараметра = Неопределено Тогда
			ЗначениеПоля = Сеанс_Свойства.Получить(ОписаниеПараметра["Имя"]);
		КонецЕсли;
	КонецЕсли;

	Возврат ЗначениеПоля;
	    
КонецФункции // Получить()
	
// Функция возвращает список лицензий, выданных сеансу 1С
//   
// Параметры:
//   ОбновитьПринудительно   - Булево        - Истина - обновить данные лицензий (вызов RAC)
//
// Возвращаемое значение:
//    ОбъектыКластера - список лицензий, выданных сеансу 1С
//
Функция Лицензии(ОбновитьПринудительно = Ложь) Экспорт
	
	Возврат Сеанс_Лицензии;
	
КонецФункции // Лицензии()
	
// Процедура завершает сеанс в кластере 1С
//   
Процедура Завершить() Экспорт
	
	ПараметрыКоманды = Новый Соответствие();
	ПараметрыКоманды.Вставить("СтрокаПодключенияАгента"  , Кластер_Агент.СтрокаПодключения());
	ПараметрыКоманды.Вставить("ИдентификаторКластера"    , Кластер_Владелец.Ид());
	ПараметрыКоманды.Вставить("СтрокаАвторизацииКластера", Кластер_Владелец.СтрокаАвторизации());
	
	ПараметрыКоманды.Вставить("ИдентификаторСеанса"      , Ид());

	ПараметрыОбъекта.УстановитьЗначенияПараметровКоманд(ПараметрыКоманды);

	КодВозврата = Кластер_Агент.ВыполнитьКоманду(ПараметрыОбъекта.ПараметрыКоманды("Удалить"));

	Если НЕ КодВозврата = 0 Тогда
		ВызватьИсключение СтрШаблон("Ошибка завершения сеанса ""%1"": %2",
	                                Ид(),
	                                Кластер_Агент.ВыводКоманды(Ложь));
	КонецЕсли;
	
	Лог.Отладка(Кластер_Агент.ВыводКоманды(Ложь));

КонецПроцедуры // Завершить()
