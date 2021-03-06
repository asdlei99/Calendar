QT += core gui xml

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets network multimedia

CONFIG(static): DEFINES *= TASKS_STATIC_DEFINE
else: DEFINES *= Tasks_EXPORTS

# The following define makes your compiler emit warnings if you use
# any feature of Qt which has been marked as deprecated (the exact warnings
# depend on your compiler). Please consult the documentation of the
# deprecated API in order to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS
CONFIG *= C++11
msvc {
    QMAKE_CXXFLAGS += "/utf-8"
    QMAKE_LFLAGS *= /SUBSYSTEM:WINDOWS",5.01"
    LIBS += User32.lib
}
# You can also make your code fail to compile if you use deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

INCLUDEPATH += $$PWD $$PWD/export

SOURCES += \
    $$PWD/DlgContainer.cpp \
    $$PWD/DlgTaskActivity.cpp \
    $$PWD/FrmCustomActivity.cpp \
    $$PWD/FrmTask.cpp \
    $$PWD/FrmTopActivity.cpp \
    $$PWD/Task.cpp \
    $$PWD/TaskActivity.cpp \
    $$PWD/Tasks.cpp \
    $$PWD/TasksList.cpp \
    $$PWD/TaskLockScreen.cpp \
    $$PWD/TaskTrayIconPrompt.cpp \
    $$PWD/FrmTop.cpp \
    $$PWD/TaskPrompt.cpp \
    $$PWD/FrmStickyNotes.cpp \
    $$PWD/Global/Log.cpp \
    $$PWD/FrmFullScreen.cpp \
    $$PWD/FrmTaskPropery.cpp \
    $$PWD/ViewTaskProperty.cpp \ 
    $$PWD/FrmTasks.cpp \  
    $$PWD/TaskPromptDelay.cpp \
    $$PWD/FrmTasksList.cpp \
    $$PWD/Sticky.cpp \
    $$PWD/FrmStickyList.cpp \
    $$PWD/StickyModel.cpp \
    $$PWD/StickyItemDelegate.cpp \
    $$PWD/FrmCalendar.cpp \
    $$PWD/TaskCycleWeek.cpp \
    $$PWD/TaskDay.cpp \
    $$PWD/Global/TasksTools.cpp

INSTALLHEADER_FILES = $$PWD/FrmTasksList.h \
        $$PWD/FrmStickyList.h \
        $$PWD/Global/GlobalDir.h \
        $$PWD/FrmCalendar.h \
        $$PWD/Global/TasksTools.h \
        $$PWD/export/tasks_export.h \
        $$PWD/export/tasks_export_windows.h \
        $$PWD/export/tasks_export_linux.h

HEADERS += $${INSTALLHEADER_FILES} \
    $$PWD/DlgContainer.h \
    $$PWD/DlgTaskActivity.h \
    $$PWD/FrmCustomActivity.h \
    $$PWD/FrmTask.h \
    $$PWD/FrmTopActivity.h \
    $$PWD/Task.h \
    $$PWD/TaskActivity.h \
    $$PWD/Tasks.h \
    $$PWD/TasksList.h \
    $$PWD/TaskLockScreen.h \
    $$PWD/TaskTrayIconPrompt.h \
    $$PWD/FrmTop.h \
    $$PWD/TaskPrompt.h \
    $$PWD/FrmStickyNotes.h \
    $$PWD/Global/Log.h \
    $$PWD/FrmFullScreen.h \
    $$PWD/ObjectFactory.h \
    $$PWD/FrmTaskPropery.h \
    $$PWD/ViewTaskProperty.h \ 
    $$PWD/FrmTasks.h \  
    $$PWD/TaskPromptDelay.h \
    $$PWD/Sticky.h \
    $$PWD/StickyModel.h \
    $$PWD/StickyItemDelegate.h \
    $$PWD/TaskCycleWeek.h \
    $$PWD/TaskDay.h  

FORMS += \
    $$PWD/DlgContainer.ui \
    $$PWD/DlgTaskActivity.ui \
    $$PWD/FrmCustomActivity.ui \
    $$PWD/FrmFullScreen.ui \
    $$PWD/FrmTask.ui \
    $$PWD/FrmTop.ui \
    $$PWD/FrmStickyNotes.ui \
    $$PWD/FrmTaskProperty.ui \ 
    $$PWD/FrmTasks.ui \
    $$PWD/FrmTasksList.ui \
    $$PWD/FrmStickyList.ui

RESOURCES += \
    $$PWD/Resource/ResourceTasks.qrc

DISTFILES += $$PWD/Resource/sink/* \
    $$PWD/Resource/db/*

TRANSLATIONS_DIR=$$PWD
TRANSLATIONS_NAME=Tasks
include(../pri/Translations.pri)

#include(../3th_libs/LunarCalendar/Src/LunarCalendar.pri)
