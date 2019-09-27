// ----------------------------------------------------------
// This Source Code Form is subject to the terms of the
// Mozilla Public License, v.2.0. If a copy of the MPL
// was not distributed with this file, You can obtain one
// at http://mozilla.org/MPL/2.0/.
// ----------------------------------------------------------
// Codebase: https://github.com/ArKuznetsov/irac/
// ----------------------------------------------------------

Перем Кластер_Ид;            // cluster
Перем Кластер_Имя;            // name
Перем Кластер_АдресСервера;    // host
Перем Кластер_ПортСервера;    // port
Перем Кластер_Свойства;

Перем Кластер_Агент;
Перем Кластер_Администраторы;
Перем ИБ_Администраторы;
Перем Кластер_Серверы;
Перем Кластер_Менеджеры;
Перем Кластер_Процессы;
Перем Кластер_Сервисы;
Перем Кластер_Сеансы;
Перем Кластер_Соединения;
Перем Кластер_Блокировки;
Перем Кластер_ИБ;
Перем Кластер_Профили;
Перем Кластер_Счетчики;

Перем ПараметрыОбъекта;

Перем ПериодОбновления;
Перем МоментАктуальности;

Перем Лог;

// Конструктор
//   
// Параметры:
//   АгентКластера          - АгентКластера           - ссылка на родительский объект агента кластера
//   Кластер                - Строка, Соответствие    - идентификатор кластера или параметры кластера
//   Администратор          - Строка                  - имя администратора кластера 1С
//   ПарольАдминистратора   - Строка                  - пароль администратора кластера 1С
//
Процедура ПриСозданииОбъекта(АгентКластера, Кластер, Администратор = "", ПарольАдминистратора = "")

	Лог = Служебный.Лог();

	Если НЕ ЗначениеЗаполнено(Кластер) Тогда
		Возврат;
	КонецЕсли;

	ПараметрыОбъекта = Новый КомандыОбъекта(Перечисления.РежимыАдминистрирования.Кластеры);

	Кластер_Агент = АгентКластера;
	
	Если ТипЗнч(Кластер) = Тип("Соответствие") Тогда
		Кластер_Ид = Кластер["cluster"];
		ЗаполнитьПараметрыКластера(Кластер);
		МоментАктуальности = ТекущаяУниверсальнаяДатаВМиллисекундах();
	Иначе
		Кластер_Ид = Кластер;
		МоментАктуальности = 0;
	КонецЕсли;

	Если ЗначениеЗаполнено(Администратор) Тогда
		Кластер_Агент.ДобавитьАдминистратораКластера(Кластер_Ид, Администратор, ПарольАдминистратора);
	КонецЕсли;

	ПериодОбновления = 60000;
	
	Кластер_Администраторы = Новый АдминистраторыКластера(Кластер_Агент, ЭтотОбъект);
	Кластер_Серверы        = Новый СерверыКластера(Кластер_Агент, ЭтотОбъект);
	Кластер_Менеджеры      = Новый МенеджерыКластера(Кластер_Агент, ЭтотОбъект);
	Кластер_Процессы       = Новый РабочиеПроцессы(Кластер_Агент, ЭтотОбъект);
	Кластер_Сервисы        = Новый Сервисы(Кластер_Агент, ЭтотОбъект);
	Кластер_ИБ             = Новый ИнформационныеБазы(Кластер_Агент, ЭтотОбъект);
	Кластер_Сеансы         = Новый Сеансы(Кластер_Агент, ЭтотОбъект);
	Кластер_Соединения     = Новый Соединения(Кластер_Агент, ЭтотОбъект);
	Кластер_Блокировки     = Новый Блокировки(Кластер_Агент, ЭтотОбъект);
	Кластер_Профили        = Новый ПрофилиБезопасности(Кластер_Агент, ЭтотОбъект);
	Кластер_Счетчики       = Новый СчетчикиРесурсов(Кластер_Агент, ЭтотОбъект);
	
	Кластер_Свойства       = Неопределено;

КонецПроцедуры // ПриСозданииОбъекта()

// Процедура получает данные от сервиса администрирования кластера 1С
// и сохраняет в локальных переменных
//   
// Параметры:
//   ОбновитьПринудительно        - Булево    - Истина - принудительно обновить данные (вызов RAC)
//                                            - Ложь - данные будут получены если истекло время актуальности
//                                                     или данные не были получены ранее
//   
Процедура ОбновитьДанные(ОбновитьПринудительно = Ложь) Экспорт

	Если НЕ Служебный.ТребуетсяОбновление(Кластер_Свойства,
			МоментАктуальности, ПериодОбновления, ОбновитьПринудительно) Тогда
		Возврат;
	КонецЕсли;

	ПараметрыКоманды = Новый Соответствие();
	ПараметрыКоманды.Вставить("СтрокаПодключенияАгента"   , Кластер_Агент.СтрокаПодключения());
	ПараметрыКоманды.Вставить("ИдентификаторКластера"     , Ид());

	ПараметрыОбъекта.УстановитьЗначенияПараметровКоманд(ПараметрыКоманды);
	    
	Кластер_Агент.ВыполнитьКоманду(ПараметрыОбъекта.ПараметрыКоманды("Описание"));

	МассивРезультатов = Кластер_Агент.ВыводКоманды();

	Если МассивРезультатов.Количество() = 0 Тогда
		Возврат;
	КонецЕсли;
	
	ЗаполнитьПараметрыКластера(МассивРезультатов[0]);

	МоментАктуальности = ТекущаяУниверсальнаяДатаВМиллисекундах();

КонецПроцедуры // ОбновитьДанные()

// Процедура заполняет параметры кластера 1С
//   
// Параметры:
//   ДанныеЗаполнения        - Соответствие        - данные, из которых будут заполнены параметры кластера
//   
Процедура ЗаполнитьПараметрыКластера(ДанныеЗаполнения)

	Кластер_АдресСервера    = ДанныеЗаполнения.Получить("host");
	Кластер_ПортСервера     = ДанныеЗаполнения.Получить("port");
	Кластер_Имя             = ДанныеЗаполнения.Получить("name");

	Служебный.ЗаполнитьСвойстваОбъекта(ЭтотОбъект, Кластер_Свойства, ДанныеЗаполнения);

КонецПроцедуры // ЗаполнитьПараметрыКластера()

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

// Функция возвращает строку параметров авторизации в кластере 1С
//   
// Возвращаемое значение:
//    Строка - строка параметров авторизации в кластере 1С
//
Функция СтрокаАвторизации() Экспорт
	
	ПараметрыАдминистратора = Кластер_Агент.ПолучитьАдминистратораКластера(Ид());

	Если НЕ ТипЗнч(ПараметрыАдминистратора)  = Тип("Структура") Тогда
		Возврат "";
	КонецЕсли;

	Если НЕ ПараметрыАдминистратора.Свойство("Администратор") Тогда
		Возврат "";
	КонецЕсли;

	Если ПустаяСтрока(ПараметрыАдминистратора.Администратор) Тогда
		Возврат "";
	КонецЕсли;

	СтрокаАвторизации = СтрШаблон("--cluster-user=%1", Служебный.ОбернутьВКавычки(ПараметрыАдминистратора.Администратор));
	
	Если Не ПустаяСтрока(ПараметрыАдминистратора.Пароль) Тогда
		СтрокаАвторизации = СтрокаАвторизации + СтрШаблон(" --cluster-pwd=%1", ПараметрыАдминистратора.Пароль);
	КонецЕсли;
	        
	Возврат СтрокаАвторизации;
	
КонецФункции // СтрокаАвторизации()
	
// Процедура устанавливает параметры авторизации в кластере 1С
//   
// Параметры:
//   Администратор         - Строка    - администратор кластера 1С
//   Пароль                - Строка    - пароль администратора кластера 1С
//
Процедура УстановитьАдминистратора(Администратор, Пароль) Экспорт
	
	Кластер_Агент.ДобавитьАдминистратораКластера(Ид(), Администратор, Пароль);
	
КонецПроцедуры // УстановитьАдминистратора()
	
// Процедура добавляет параметры авторизации для указанной информационной базы
//   
// Параметры:
//   ИБ_Ид              - Строка    - идентификатор информационной базы в кластере
//   Администратор      - Строка    - администратор информационной базы
//   Пароль             - Строка    - пароль администратора информационной базы
//
Процедура ДобавитьАдминистратораИБ(ИБ_Ид, Администратор, Пароль) Экспорт

	Если НЕ ТипЗнч(ИБ_Администраторы) = Тип("Соответствие") Тогда
		ИБ_Администраторы = Новый Соответствие();
	КонецЕсли;

	ИБ_Администраторы.Вставить(ИБ_Ид, Новый Структура("Администратор, Пароль", Администратор, Пароль));

КонецПроцедуры // ДобавитьАдминистратораИБ()

// Функция возвращает параметры авторизации для указанной информационной базы
//   
// Параметры:
//   ИБ_Ид              - Строка    - идентификатор информационной базы в кластере
//
// Возвращаемое значение:
//   Структура         - параметры администратора
//       Администратор      - Строка    - администратор информационной базы
//       Пароль             - Строка    - пароль администратора информационной базы
//
Функция ПолучитьАдминистратораИБ(ИБ_Ид) Экспорт

	Если НЕ ТипЗнч(ИБ_Администраторы) = Тип("Соответствие") Тогда
		Возврат Неопределено;
	КонецЕсли;

	Возврат ИБ_Администраторы.Получить(ИБ_Ид); 

КонецФункции // ПолучитьАдминистратораИБ()

// Функция возвращает идентификатор кластера 1С
//   
// Возвращаемое значение:
//    Строка - идентификатор кластера 1С
//
Функция Ид() Экспорт

	Возврат Кластер_Ид;

КонецФункции // Ид()

// Функция возвращает имя кластера 1С
//   
// Возвращаемое значение:
//    Строка - имя кластера 1С
//
Функция Имя() Экспорт

	Если Служебный.ТребуетсяОбновление(Кластер_Имя, МоментАктуальности, ПериодОбновления) Тогда
		ОбновитьДанные(Истина);
	КонецЕсли;

	Возврат Кластер_Имя;
	
КонецФункции // Имя()

// Функция возвращает адрес сервера кластера 1С
//   
// Возвращаемое значение:
//    Строка - адрес сервера кластера 1С
//
Функция АдресСервера() Экспорт
	
	Если Служебный.ТребуетсяОбновление(Кластер_АдресСервера, МоментАктуальности, ПериодОбновления) Тогда
		ОбновитьДанные(Истина);
	КонецЕсли;

	Возврат Кластер_АдресСервера;
	    
КонецФункции // АдресСервера()
	
// Функция возвращает порт сервера кластера 1С
//   
// Возвращаемое значение:
//    Строка - порт сервера кластера 1С
//
Функция ПортСервера() Экспорт
	
	Если Служебный.ТребуетсяОбновление(Кластер_ПортСервера, МоментАктуальности, ПериодОбновления) Тогда
		ОбновитьДанные(Истина);
	КонецЕсли;

	Возврат Кластер_ПортСервера;
	    
КонецФункции // ПортСервера()
	
// Функция возвращает список администраторов кластера 1С
//   
// Возвращаемое значение:
//    Соответствие - список администраторов кластера 1С
//
Функция Администраторы() Экспорт

	Возврат Кластер_Администраторы;

КонецФункции // Администраторы()

// Функция возвращает список серверов кластера 1С
//   
// Возвращаемое значение:
//    СерверыКластера - список серверов кластера 1С
//
Функция Серверы() Экспорт
	
	Возврат Кластер_Серверы;
	
КонецФункции // Серверы()
	
// Функция возвращает список менеджеров кластера 1С
//   
// Возвращаемое значение:
//    МенеджерыКластера - список менеджеров кластера 1С
//
Функция Менеджеры() Экспорт
	
	Возврат Кластер_Менеджеры;
	
КонецФункции // Менеджеры()
	
// Функция возвращает список рабочих процессов 1С
//   
// Возвращаемое значение:
//    РабочиеПроцессы - список рабочих процессов 1С
//
Функция РабочиеПроцессы() Экспорт
	
	Возврат Кластер_Процессы;
	
КонецФункции // РабочиеПроцессы()
	
// Функция возвращает список сервисов 1С
//   
// Возвращаемое значение:
//    РабочиеПроцессы - список сервисов 1С
//
Функция Сервисы() Экспорт
	
	Возврат Кластер_Сервисы;
	
КонецФункции // Сервисы()
	
// Функция возвращает список информационных баз 1С
//   
// Возвращаемое значение:
//    ИнформационныеБазы - список информационных баз 1С
//
Функция ИнформационныеБазы() Экспорт
	
	Возврат Кластер_ИБ;
	
КонецФункции // ИнформационныеБазы()
	
// Функция возвращает список сеансов 1С
//   
// Возвращаемое значение:
//    Сеансы - список сеансов 1С
//
Функция Сеансы() Экспорт
	
	Возврат Кластер_Сеансы;
	
КонецФункции // Сеансы()
	
// Функция возвращает список соединений 1С
//   
// Возвращаемое значение:
//    Сеансы - список соединений 1С
//
Функция Соединения() Экспорт
	
	Возврат Кластер_Соединения;
	
КонецФункции // Соединения()
	
// Функция возвращает список блокировок 1С
//   
// Возвращаемое значение:
//    Сеансы - список блокировок 1С
//
Функция Блокировки() Экспорт
	
	Возврат Кластер_Блокировки;
	
КонецФункции // Блокировки()
	
// Функция возвращает список профилей безопасности кластера 1С
//   
// Возвращаемое значение:
//    Сеансы - список профилей безопасности кластера 1С
//
Функция ПрофилиБезопасности() Экспорт
	
	Возврат Кластер_Профили;
	
КонецФункции // ПрофилиБезопасности()

// Функция возвращает список счетчиков ресурсов кластера 1С
//   
// Возвращаемое значение:
//    СчетчикиРесурсов - список счетчиков ресурсов кластера 1С
//
Функция СчетчикиРесурсов() Экспорт
	
	Возврат Кластер_Счетчики;
	
КонецФункции // СчетчикиРесурсов()

// Функция возвращает значение параметра кластера 1С
//   
// Параметры:
//   ИмяПоля                 - Строка        - Имя параметра кластера
//   ОбновитьПринудительно   - Булево        - Истина - обновить список (вызов RAC)
//
// Возвращаемое значение:
//    Произвольный - значение параметра кластера 1С
//
Функция Получить(ИмяПоля, ОбновитьПринудительно = Ложь) Экспорт
	
	ОбновитьДанные(ОбновитьПринудительно);

	ЗначениеПоля = Неопределено;
	
	Если НЕ Найти(ВРЕг("Ид, cluster"), ВРег(ИмяПоля)) = 0 Тогда
		Возврат Кластер_Ид;
	ИначеЕсли НЕ Найти(ВРЕг("Имя, name"), ВРег(ИмяПоля)) = 0 Тогда
		Возврат Кластер_Имя;
	ИначеЕсли НЕ Найти(ВРЕг("АдресСервера, host"), ВРег(ИмяПоля)) = 0 Тогда
		Возврат Кластер_АдресСервера;
	ИначеЕсли НЕ Найти(ВРЕг("ПортСервера, port"), ВРег(ИмяПоля)) = 0 Тогда
		Возврат Кластер_ПортСервера;
	Иначе
		ЗначениеПоля = Кластер_Свойства.Получить(ИмяПоля);
	КонецЕсли;
	
	Если ЗначениеПоля = Неопределено Тогда
	    
		ОписаниеПараметра = ПараметрыОбъекта("ИмяРАК").Получить(ИмяПоля);

		Если НЕ ОписаниеПараметра = Неопределено Тогда
			ЗначениеПоля = Кластер_Свойства.Получить(ОписаниеПараметра["Имя"]);
		КонецЕсли;
	КонецЕсли;

	Возврат ЗначениеПоля;
	    
КонецФункции // Получить()
	
// Процедура изменяет параметры кластера
//   
// Параметры:
//   Имя                     - Строка        - новое имя кластера
//   ПараметрыКластера       - Структура        - новые параметры кластера
//
Процедура Изменить(Знач Имя = "", Знач ПараметрыКластера = Неопределено) Экспорт

	Если НЕ ТипЗнч(ПараметрыКластера) = Тип("Структура") Тогда
		ПараметрыКластера = Новый Структура();
	КонецЕсли;

	ПараметрыКоманды = Новый Соответствие();
	ПараметрыКоманды.Вставить("СтрокаПодключенияАгента", Кластер_Агент.СтрокаПодключения());
	ПараметрыКоманды.Вставить("СтрокаАвторизацииАгента", Кластер_Агент.СтрокаАвторизации());
	ПараметрыКоманды.Вставить("ИдентификаторКластера"  , Ид());

	Если ЗначениеЗаполнено(Имя) Тогда
		ПараметрыКоманды.Вставить("Имя"                , Имя);
	КонецЕсли;

	Для Каждого ТекЭлемент Из ПараметрыКластера Цикл
		ПараметрыКоманды.Вставить(ТекЭлемент.Ключ, ТекЭлемент.Значение);
	КонецЦикла;

	ПараметрыОбъекта.УстановитьЗначенияПараметровКоманд(ПараметрыКоманды);

	Кластер_Агент.ВыполнитьКоманду(ПараметрыОбъекта.ПараметрыКоманды("Изменить"));

	Лог.Отладка(Кластер_Агент.ВыводКоманды(Ложь));

	Кластер_Свойства = Неопределено;

КонецПроцедуры // Изменить()
