Перем Кластер_Агент;
Перем Кластер_Владелец;
Перем Элементы;

Перем Лог;

// Конструктор
//   
// Параметры:
//   АгентКластера		- АгентКластера	- ссылка на родительский объект агента кластера
//   Кластер			- Кластер		- ссылка на родительский объект кластера
//
Процедура ПриСозданииОбъекта(АгентКластера, Кластер)

	Кластер_Агент = АгентКластера;
	Кластер_Владелец = Кластер;

	Элементы = Новый ОбъектыКластера(ЭтотОбъект);

КонецПроцедуры

// Процедура получает данные от сервиса администрирования кластера 1С
// и сохраняет в локальных переменных
//   
// Параметры:
//   ОбновитьПринудительно 		- Булево	- Истина - принудительно обновить данные (вызов RAC)
//											- Ложь - данные будут получены если истекло время актуальности
//													или данные не были получены ранее
//   
Процедура ОбновитьДанные(ОбновитьПринудительно = Ложь) Экспорт
	
	Если НЕ Элементы.ТребуетсяОбновление(ОбновитьПринудительно) Тогда
		Возврат;
	КонецЕсли;

	// TODO: Добавить просмотр лицензий
	ПараметрыЗапуска = Новый Массив();
	ПараметрыЗапуска.Добавить(Кластер_Агент.СтрокаПодключения());

	ПараметрыЗапуска.Добавить("process");
	ПараметрыЗапуска.Добавить("list");

	ПараметрыЗапуска.Добавить(СтрШаблон("--cluster=%1", Кластер_Владелец.Ид()));
	ПараметрыЗапуска.Добавить(Кластер_Владелец.СтрокаАвторизации());

	Служебный.ВыполнитьКоманду(ПараметрыЗапуска);
	
	Элементы.Заполнить(Служебный.РазобратьВыводКоманды(Служебный.ВыводКоманды()));

	Элементы.УстановитьАктуальность();

КонецПроцедуры // ОбновитьДанные()

// Функция возвращает список рабочих процессов
//   
// Параметры:
//   Отбор					 	- Структура	- Структура отбора процессов (<поле>:<значение>)
//   ОбновитьПринудительно 		- Булево	- Истина - принудительно обновить данные (вызов RAC)
//
// Возвращаемое значение:
//	Массив - список рабочих процессов 1С
//
Функция Список(Отбор = Неопределено, ОбновитьПринудительно = Ложь) Экспорт

	РабочиеПроцессы = Элементы.Список(Отбор, ОбновитьПринудительно);
	
	Возврат РабочиеПроцессы;

КонецФункции // Список()

// Функция возвращает список рабочих процессов кластера 1С
//   
// Параметры:
//   ПоляИерархии 			- Строка		- Поля для построения иерархии списка процессов, разделенные ","
//   ОбновитьПринудительно 	- Булево		- Истина - принудительно обновить данные (вызов RAC)
//
// Возвращаемое значение:
//	Соответствие - список рабочих процессов кластера 1С
//
Функция ИерархическийСписок(Знач ПоляИерархии, ОбновитьПринудительно = Ложь) Экспорт

	РабочиеПроцессы = Элементы.ИерархическийСписок(ПоляИерархии, ОбновитьПринудительно); 
	
	Возврат РабочиеПроцессы;

КонецФункции // ИерархическийСписок()

// Функция возвращает описание рабочего процесса кластера 1С
//   
// Параметры:
//   ИдПроцесса			 	- Структура	- PID рабочего процесса кластера
//   ОбновитьПринудительно 	- Булево	- Истина - принудительно обновить данные (вызов RAC)
//
// Возвращаемое значение:
//	Соответствие - описание рабочего процесса кластера 1С
//
Функция Получить(Знач ИдПроцесса, Знач ОбновитьПринудительно = Ложь) Экспорт

	Отбор = Новый Структура("pid", ИдПроцесса);
	
	РабочиеПроцессы = Элементы.Список(Отбор, ОбновитьПринудительно);

	Если РабочиеПроцессы.Количество() = 0 Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Возврат РабочиеПроцессы[0];

КонецФункции // Получить()

Лог = Логирование.ПолучитьЛог("ktb.lib.irac");
