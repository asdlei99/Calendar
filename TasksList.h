#ifndef TASLIST_H
#define TASLIST_H

#pragma once

#include <QObject>
#include "Tasks.h"
#include <QList>
#include <QSharedPointer>
#include <QTimer>

class CTasksList : public QObject
{
    Q_OBJECT
public:
    explicit CTasksList(QObject *parent = nullptr);
    virtual ~CTasksList();
    
    int Add(QSharedPointer<CTasks> tasks);
    int Remove(QSharedPointer<CTasks> tasks);
    int RemoveAll();

    /**
     * @brief Start: Initialize here
     * @return 
     */
    int Start();
    int Check();
    
    virtual int LoadSettings(const QDomElement &e);
    virtual int LoadSettings(const QString &szFile);
    virtual int SaveSettings(QDomElement &e);
    virtual int SaveSettings(const QString &szFile);
    
private Q_SLOTS:
    void slotTimeout();
    
private:
    QList<QSharedPointer<CTasks>> m_lstTasks;
    QTimer m_Timer;
    int m_nTimerInterval;
};

#endif // TASLIST_H
